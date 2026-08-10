<?php

declare(strict_types=1);

require_once 'config.php';

function connectDatabase(?array $connection = null): PDO
{
    $connection = $connection ?? [
        'host' => DB_HOST,
        'port' => DB_PORT,
        'database' => DB_NAME,
        'username' => DB_USER,
        'password' => DB_PASS,
        'authentication' => 'password'
    ];

    $host = trim((string)($connection['host'] ?? ''));
    $port = (int)($connection['port'] ?? 0);
    $database = trim((string)($connection['database'] ?? ''));
    $username = (string)($connection['username'] ?? '');
    $password = (string)($connection['password'] ?? '');

    if ($host === '')
    {
        throw new InvalidArgumentException('Database host is required.');
    }

    if ($port < 1 || $port > 65535)
    {
        throw new InvalidArgumentException('Database port must be between 1 and 65535.');
    }

    if ($database === '')
    {
        throw new InvalidArgumentException('Database name is required.');
    }

    if ($username === '')
    {
        throw new InvalidArgumentException('Database user name is required.');
    }

    return new PDO(
        sprintf(
            'mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4',
            $host,
            $port,
            $database
        ),
        $username,
        $password,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]
    );
}
