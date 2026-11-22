<?php
declare(strict_types=1);

function conectarBanco(): PDO
{
    $host = '127.0.0.1';
    $porta = '3306';
    $banco = 'taskcloud';

    $usuario = getenv('TASKCLOUD_DB_USER') ?: 'root';
    $senha = getenv('TASKCLOUD_DB_PASSWORD');

    if ($senha === false) {
        $senha = '';
    }

    $dsn = "mysql:host={$host};port={$porta};dbname={$banco};charset=utf8mb4";

    return new PDO($dsn, $usuario, $senha, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
}
