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

    $stmt = $pdo->query(
        'SELECT VERSION() AS version'
    );

    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    $version = $result['version'] ?? 'unknown';

    echo 'Connection successful.' .
         "\n\n" .
         'MySQL version: ' .
         $version;


    /*
       Check for Easy Pivot stored procedure
    */

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
catch (Throwable $e)
{
    http_response_code(500);

    echo $e->getMessage();
}