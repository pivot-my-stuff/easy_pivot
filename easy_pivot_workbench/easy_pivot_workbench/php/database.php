<?php

declare(strict_types=1);

require_once 'config.php';

function connectDatabase(?array $connection = null): PDO
{
    $connection = $connection ?? [
        'databaseType' => 'mysql',
        'host' => DB_HOST,
        'port' => DB_PORT,
        'database' => DB_NAME,
        'username' => DB_USER,
        'password' => DB_PASS,
        'authentication' => 'password'
    ];

    $databaseType =
        strtolower(
            trim(
                (string)($connection['databaseType'] ?? 'mysql')
            )
        );

    $host =
        trim(
            (string)($connection['host'] ?? '')
        );

    $port =
        (int)($connection['port'] ?? 0);

    $database =
        trim(
            (string)($connection['database'] ?? '')
        );

    $username =
        (string)($connection['username'] ?? '');

    $password =
        (string)($connection['password'] ?? '');

    $authentication =
        strtolower(
            trim(
                (string)($connection['authentication'] ?? 'password')
            )
        );

    if ($host === '')
    {
        throw new InvalidArgumentException(
            'Database host is required.'
        );
    }

    if ($port < 1 || $port > 65535)
    {
        throw new InvalidArgumentException(
            'Database port must be between 1 and 65535.'
        );
    }

    if ($database === '')
    {
        throw new InvalidArgumentException(
            'Database name is required.'
        );
    }

    if ($authentication !== 'windows' &&
        $username === '')
    {
        throw new InvalidArgumentException(
            'Database user name is required.'
        );
    }

    switch ($databaseType)
    {
        case 'mysql':

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
                    PDO::ATTR_ERRMODE =>
                        PDO::ERRMODE_EXCEPTION,

                    PDO::ATTR_DEFAULT_FETCH_MODE =>
                        PDO::FETCH_ASSOC,

                    PDO::ATTR_EMULATE_PREPARES =>
                        false,
                ]
            );


        case 'postgresql':

            $dsn =
                sprintf(
                    'pgsql:host=%s;port=%d;dbname=%s',
                    $host,
                    $port,
                    $database
                );

            if ($authentication === 'windows')
            {
                /*
                    Windows Authentication

                    Do not supply a user name or password.
                    libpq/PDO_PGSQL will use the Windows identity
                    of the PHP process when the PostgreSQL server
                    requests SSPI authentication.
                */
                return new PDO(
                    $dsn,
                    null,
                    null,
                    [
                        PDO::ATTR_ERRMODE =>
                            PDO::ERRMODE_EXCEPTION,

                        PDO::ATTR_DEFAULT_FETCH_MODE =>
                            PDO::FETCH_ASSOC,
                    ]
                );
            }

            return new PDO(
                $dsn,
                $username,
                $password,
                [
                    PDO::ATTR_ERRMODE =>
                        PDO::ERRMODE_EXCEPTION,

                    PDO::ATTR_DEFAULT_FETCH_MODE =>
                        PDO::FETCH_ASSOC,
                ]
            );


        case 'oracle':

            return new PDO(
                sprintf(
                    'oci:dbname=//%s:%d/%s;charset=AL32UTF8',
                    $host,
                    $port,
                    $database
                ),
                $username,
                $password,
                [
                    PDO::ATTR_ERRMODE =>
                        PDO::ERRMODE_EXCEPTION,

                    PDO::ATTR_DEFAULT_FETCH_MODE =>
                        PDO::FETCH_ASSOC,
                ]
            );


        case 'sqlserver':

            $dsn =
                sprintf(
                    'sqlsrv:Server=%s,%d;Database=%s',
                    $host,
                    $port,
                    $database
                );

            if ($authentication === 'windows')
            {
                /*
                    Windows Authentication

                    Do not supply a user name or password.
                    PDO_SQLSRV will use the Windows identity of
                    the PHP process.
                */
                return new PDO(
                    $dsn,
                    null,
                    null,
                    [
                        PDO::ATTR_ERRMODE =>
                            PDO::ERRMODE_EXCEPTION,

                        PDO::ATTR_DEFAULT_FETCH_MODE =>
                            PDO::FETCH_ASSOC,
                    ]
                );
            }

            return new PDO(
                $dsn,
                $username,
                $password,
                [
                    PDO::ATTR_ERRMODE =>
                        PDO::ERRMODE_EXCEPTION,

                    PDO::ATTR_DEFAULT_FETCH_MODE =>
                        PDO::FETCH_ASSOC,
                ]
            );


        default:

            throw new InvalidArgumentException(
                'Unsupported database type: ' .
                $databaseType
            );
    }

}