<?php
declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');

function resposta(int $status, array $dados): never
{
    http_response_code($status);
    echo json_encode($dados, JSON_UNESCAPED_UNICODE);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Allow: POST');
    resposta(405, ['erro' => 'Metodo nao permitido.']);
}

if (!str_starts_with(
    strtolower($_SERVER['CONTENT_TYPE'] ?? ''),
    'application/json'
)) {
    resposta(415, ['erro' => 'Envie JSON.']);
}

$conteudo = file_get_contents('php://input', false, null, 0, 8193);

if ($conteudo === false || strlen($conteudo) > 8192) {
    resposta(413, ['erro' => 'Requisicao muito grande.']);
}

$dados = json_decode($conteudo, true);

if (!is_array($dados)) {
    resposta(400, ['erro' => 'JSON invalido.']);
}

$email = strtolower(trim((string) ($dados['email'] ?? '')));
$senha = $dados['senha'] ?? null;

if (
    !filter_var($email, FILTER_VALIDATE_EMAIL) ||
    strlen($email) > 254 ||
    !is_string($senha) ||
    $senha === ''
) {
    resposta(422, ['erro' => 'Dados de login invalidos.']);
}

try {
    $pdo = conectarBanco();

    $consulta = $pdo->prepare(
        'SELECT
            u.id,
            u.empresa_id,
            u.nome,
            u.email,
            u.senha_hash,
            u.papel,
            u.status,
            e.status AS empresa_status
         FROM usuarios u
         INNER JOIN empresas e ON e.id = u.empresa_id
         WHERE u.email = ?
         LIMIT 1'
    );

    $consulta->execute([$email]);
    $usuario = $consulta->fetch();

    if (
        !$usuario ||
        $usuario['status'] !== 'ativo' ||
        $usuario['empresa_status'] !== 'ativa' ||
        !password_verify($senha, $usuario['senha_hash'])
    ) {
        resposta(401, ['erro' => 'E-mail ou senha invalidos.']);
    }

    $token = bin2hex(random_bytes(32));
    $tokenHash = hash('sha256', $token);

    $agora = new DateTimeImmutable('now', new DateTimeZone('UTC'));
    $expiracao = $agora->modify('+30 minutes');

    $pdo->beginTransaction();

    $sessao = $pdo->prepare(
        'INSERT INTO sessoes_usuario
         (empresa_id, usuario_id, identificador_hash,
          criado_em, ultima_atividade_em, expira_em,
          endereco_ip, user_agent)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
    );

    $ip = $_SERVER['REMOTE_ADDR'] ?? null;
    $ipBinario = $ip !== null ? @inet_pton($ip) : false;

    $sessao->execute([
        $usuario['empresa_id'],
        $usuario['id'],
        $tokenHash,
        $agora->format('Y-m-d H:i:s'),
        $agora->format('Y-m-d H:i:s'),
        $expiracao->format('Y-m-d H:i:s'),
        $ipBinario !== false ? $ipBinario : null,
        substr($_SERVER['HTTP_USER_AGENT'] ?? '', 0, 512)
    ]);

    $atualizar = $pdo->prepare(
        'UPDATE usuarios
         SET ultimo_login_em = ?
         WHERE id = ? AND empresa_id = ?'
    );

    $atualizar->execute([
        $agora->format('Y-m-d H:i:s'),
        $usuario['id'],
        $usuario['empresa_id']
    ]);

    $pdo->commit();

    setcookie('taskcloud_session', $token, [
        'expires' => $expiracao->getTimestamp(),
        'path' => '/',
        'secure' => !empty($_SERVER['HTTPS']) &&
                    $_SERVER['HTTPS'] !== 'off',
        'httponly' => true,
        'samesite' => 'Lax'
    ]);

    resposta(200, [
        'mensagem' => 'Login realizado com sucesso.',
        'usuario' => [
            'id' => (int) $usuario['id'],
            'nome' => $usuario['nome'],
            'papel' => $usuario['papel'],
            'empresa_id' => (int) $usuario['empresa_id']
        ]
    ]);

} catch (Throwable $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }

    error_log('Erro no login TaskCloud: ' . $e->getMessage());

    resposta(500, [
        'erro' => 'Nao foi possivel realizar o login.'
    ]);
}