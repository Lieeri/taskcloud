<?php
declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');

function responder(int $status, array $dados): never
{
    http_response_code($status);
    echo json_encode($dados, JSON_UNESCAPED_UNICODE);
    exit;
}

function cnpjValido(string $cnpj): bool
{
    if (!preg_match('/^\d{14}$/', $cnpj)) {
        return false;
    }

    if (preg_match('/^(\d)\1{13}$/', $cnpj)) {
        return false;
    }

    for ($tamanho = 12; $tamanho <= 13; $tamanho++) {
        $soma = 0;
        $peso = $tamanho === 12 ? 5 : 6;

        for ($i = 0; $i < $tamanho; $i++) {
            $soma += (int) $cnpj[$i] * $peso;
            $peso = $peso === 2 ? 9 : $peso - 1;
        }

        $resto = $soma % 11;
        $digito = $resto < 2 ? 0 : 11 - $resto;

        if ((int) $cnpj[$tamanho] !== $digito) {
            return false;
        }
    }

    return true;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Allow: POST');
    responder(405, ['erro' => 'Método não permitido.']);
}

if (!str_starts_with(
    strtolower($_SERVER['CONTENT_TYPE'] ?? ''),
    'application/json'
)) {
    responder(415, ['erro' => 'Envie os dados em JSON.']);
}

$entrada = file_get_contents('php://input', false, null, 0, 16385);

if ($entrada === false || strlen($entrada) > 16384) {
    responder(413, ['erro' => 'Requisição muito grande.']);
}

$dados = json_decode($entrada, true);

if (!is_array($dados) || array_is_list($dados)) {
    responder(400, ['erro' => 'JSON inválido.']);
}

$razao = trim((string) ($dados['razao_social'] ?? ''));
$fantasia = trim((string) ($dados['nome_fantasia'] ?? ''));
$cnpj = preg_replace('/\D/', '', (string) ($dados['cnpj'] ?? ''));
$emailEmpresa = strtolower(trim((string) ($dados['email_contato'] ?? '')));
$nome = trim((string) ($dados['nome_principal'] ?? ''));
$email = strtolower(trim((string) ($dados['email_principal'] ?? '')));
$senha = $dados['senha'] ?? null;

if (
    $razao === '' || mb_strlen($razao) > 200 ||
    mb_strlen($fantasia) > 200 ||
    $nome === '' || mb_strlen($nome) > 150 ||
    !cnpjValido($cnpj) ||
    !filter_var($emailEmpresa, FILTER_VALIDATE_EMAIL) ||
    strlen($emailEmpresa) > 254 ||
    !filter_var($email, FILTER_VALIDATE_EMAIL) ||
    strlen($email) > 254 ||
    !is_string($senha) ||
    strlen($senha) < 12 ||
    strlen($senha) > 128
) {
    responder(422, [
        'erro' => 'Dados inválidos. Verifique CNPJ, e-mails, campos e senha de 12 a 128 caracteres.'
    ]);
}

try {
    $pdo = conectarBanco();
    $pdo->beginTransaction();

    $empresa = $pdo->prepare(
        'INSERT INTO empresas
         (razao_social, nome_fantasia, cnpj, email_contato,
          status, criado_em, atualizado_em)
         VALUES (?, ?, ?, ?, ?, NOW(), NOW())'
    );

    $empresa->execute([
        $razao,
        $fantasia !== '' ? $fantasia : null,
        $cnpj,
        $emailEmpresa,
        'ativa'
    ]);

    $empresaId = (int) $pdo->lastInsertId();

    $usuario = $pdo->prepare(
        'INSERT INTO usuarios
         (empresa_id, nome, email, senha_hash, papel,
          status, criado_em, atualizado_em)
         VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW())'
    );

    $usuario->execute([
        $empresaId,
        $nome,
        $email,
        password_hash($senha, PASSWORD_DEFAULT),
        'principal',
        'ativo'
    ]);

    $pdo->commit();

    responder(201, [
        'mensagem' => 'Empresa e usuário principal cadastrados.',
        'empresa_id' => $empresaId
    ]);
} catch (PDOException $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }

    error_log('Erro no cadastro TaskCloud: ' . $e->getMessage());

    if ($e->getCode() === '23000') {
        responder(409, ['erro' => 'CNPJ ou e-mail já cadastrado.']);
    }

    responder(500, ['erro' => 'Não foi possível concluir o cadastro.']);
} catch (Throwable $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }

    error_log('Falha no cadastro TaskCloud: ' . $e->getMessage());
    responder(500, ['erro' => 'Não foi possível concluir o cadastro.']);
}
