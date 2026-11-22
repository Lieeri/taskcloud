<?php
declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';

function exigirAutenticacao(bool $renovarAtividade = false): array
{
    $token = $_COOKIE['taskcloud_session'] ?? '';

    if (
        !is_string($token) ||
        !preg_match('/^[a-f0-9]{64}$/D', $token)
    ) {
        negarAcesso();
    }

    $pdo = conectarBanco();
    $hash = hash('sha256', $token);

    $consulta = $pdo->prepare(
        "SELECT
            s.id AS sessao_id,
            s.usuario_id,
            s.empresa_id,
            u.nome,
            u.papel
         FROM sessoes_usuario s
         INNER JOIN usuarios u
           ON u.id = s.usuario_id
          AND u.empresa_id = s.empresa_id
         INNER JOIN empresas e
           ON e.id = s.empresa_id
         WHERE s.identificador_hash = ?
           AND s.encerrado_em IS NULL
           AND s.expira_em > UTC_TIMESTAMP()
           AND s.ultima_atividade_em >
               UTC_TIMESTAMP() - INTERVAL 30 MINUTE
           AND u.status = 'ativo'
           AND e.status = 'ativa'
         LIMIT 1"
    );

    $consulta->execute([$hash]);
    $usuario = $consulta->fetch();

    if (!$usuario) {
        negarAcesso();
    }

    if ($renovarAtividade) {
        $atualizar = $pdo->prepare(
            "UPDATE sessoes_usuario
             SET ultima_atividade_em = UTC_TIMESTAMP(),
                 expira_em = UTC_TIMESTAMP() + INTERVAL 30 MINUTE
             WHERE id = ?
               AND encerrado_em IS NULL
               AND expira_em > UTC_TIMESTAMP()
               AND ultima_atividade_em >
                   UTC_TIMESTAMP() - INTERVAL 30 MINUTE"
        );

        $atualizar->execute([$usuario['sessao_id']]);

        if ($atualizar->rowCount() !== 1) {
            negarAcesso();
        }
    }

    return $usuario;
}

function negarAcesso(): never
{
    http_response_code(401);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');

    echo json_encode([
        'erro' => 'Sessao inexistente, invalida ou expirada.'
    ], JSON_UNESCAPED_UNICODE);

    exit;
}