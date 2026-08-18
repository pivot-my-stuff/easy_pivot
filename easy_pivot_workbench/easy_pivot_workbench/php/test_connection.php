<?php

declare(strict_types=1);

require_once 'database.php';

$request = json_decode(
    file_get_contents('php://input'),
    true
);

try
{
    if (!is_array($request))
    {
        throw new InvalidArgumentException(
            'Invalid request.'
        );
    }

    if (!isset($request['connection']) ||
        !is_array($request['connection']))
    {
        throw new InvalidArgumentException(
            'Database connection information is required.'
        );
    }

    $pdo = connectDatabase(
        $request['connection']
    );

    $databaseType =
        strtolower(
            trim(
                (string)($request['connection']['databaseType'] ?? 'mysql')
            )
        );


    /*
       Get database version
    */

    switch ($databaseType)
    {
        case 'mysql':

            $stmt = $pdo->query(
                'SELECT VERSION() AS version'
            );

            $result = $stmt->fetch(PDO::FETCH_ASSOC);

            $version = $result['version'] ?? 'unknown';

            echo 'Connection successful.' .
                 "\n\n" .
                 'MySQL version: ' .
                 $version;

            break;


        case 'sqlserver':

            $stmt = $pdo->query(
                'SELECT @@VERSION AS version'
            );

            $result = $stmt->fetch(PDO::FETCH_ASSOC);

            $version = $result['version'] ?? 'unknown';

            echo 'Connection successful.' .
                 "\n\n" .
                 'SQL Server version: ' .
                 $version;

            break;


        case 'postgresql':

            $stmt = $pdo->query(
                'SELECT version() AS version'
            );

            $result = $stmt->fetch(PDO::FETCH_ASSOC);

            $version = $result['version'] ?? 'unknown';

            echo 'Connection successful.' .
                 "\n\n" .
                 'PostgreSQL version: ' .
                 $version;

            break;


        default:

            echo 'Connection successful.';

            break;
    }


    /*
       Check for Easy Pivot stored procedure
    */

    if ($databaseType === 'mysql')
    {
        $stmt = $pdo->query("
            SELECT COUNT(*) AS procedure_count
            FROM information_schema.ROUTINES
            WHERE ROUTINE_SCHEMA = DATABASE()
            AND ROUTINE_NAME = 'easy_pivot'
        ");

        $procedure = $stmt->fetch(PDO::FETCH_ASSOC);

        echo "\n\n";

        if (($procedure['procedure_count'] ?? 0) > 0)
        {
            echo 'Easy Pivot procedure found.';
        }
        else
        {
            echo 'Easy Pivot procedure NOT found.';
        }
    }
    elseif ($databaseType === 'sqlserver')
    {
        $stmt = $pdo->query("
            SELECT COUNT(*) AS procedure_count
            FROM sys.procedures
            WHERE name = 'easy_pivot'
        ");

        $procedure = $stmt->fetch(PDO::FETCH_ASSOC);

        echo "\n\n";

        if (($procedure['procedure_count'] ?? 0) > 0)
        {
            echo 'Easy Pivot procedure found.';
        }
        else
        {
            echo 'Easy Pivot procedure NOT found.';
        }
    }
    elseif ($databaseType === 'postgresql')
    {
        $stmt = $pdo->query("
            SELECT COUNT(*) AS procedure_count
            FROM pg_proc
            WHERE proname = 'easy_pivot'
            AND prokind = 'p'
        ");

        $procedure = $stmt->fetch(PDO::FETCH_ASSOC);

        echo "\n\n";

        if (($procedure['procedure_count'] ?? 0) > 0)
        {
            echo 'Easy Pivot procedure found.';
        }
        else
        {
            echo 'Easy Pivot procedure NOT found.';
        }
    }

}
catch (Throwable $e)
{
    http_response_code(500);

    echo $e->getMessage();
}