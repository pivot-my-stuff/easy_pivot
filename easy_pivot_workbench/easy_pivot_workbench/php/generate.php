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

    if (!isset($request['source_query']) ||
        !isset($request['generated_json']))
    {
        throw new InvalidArgumentException(
            'Source query and generated JSON are required.'
        );
    }

    $pdo = connectDatabase(
        $request['connection']
    );

    $stmt = $pdo->prepare("
        CALL easy_pivot(
            ?,
            ?,
            TRUE,
            @warnings
        )
    ");

    $stmt->execute([
        $request['source_query'],
        $request['generated_json']
    ]);

    $result = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (empty($result) ||
        !array_key_exists('Generated_SQL', $result[0]))
    {
        throw new RuntimeException(
            'Easy Pivot did not return generated SQL.'
        );
    }

    echo $result[0]['Generated_SQL'];

    $stmt->closeCursor();

    $warnings = $pdo->query(
        "SELECT @warnings AS warnings"
    )->fetch(PDO::FETCH_ASSOC);

    if (!empty($warnings['warnings']))
    {
        echo "\n\n";
        echo $warnings['warnings'];
    }
}
catch (Throwable $e)
{
    http_response_code(500);

    echo $e->getMessage();
}
