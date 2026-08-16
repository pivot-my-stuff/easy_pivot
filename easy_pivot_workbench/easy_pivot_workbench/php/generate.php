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

    $connection =
        $request['connection'];

    $databaseType =
        strtolower(
            trim(
                (string)($connection['databaseType'] ?? 'mysql')
            )
        );

    $pdo =
        connectDatabase($connection);

    switch ($databaseType)
    {
        case 'mysql':

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

            $result =
                $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$result ||
                !array_key_exists(
                    'Generated_SQL',
                    $result
                ))
            {
                throw new RuntimeException(
                    'Easy Pivot did not return generated SQL.'
                );
            }

            echo $result['Generated_SQL'];

            $stmt->closeCursor();

            $warnings =
                $pdo->query(
                    "SELECT @warnings AS warnings"
                )->fetch(PDO::FETCH_ASSOC);

            if (!empty($warnings['warnings']))
            {
                echo "\n\n";
                echo $warnings['warnings'];
            }

            break;


        case 'postgresql':

            /*
                PostgreSQL uses the procedure's refcursor
                to return the generated SQL.
            */

            $pdo->beginTransaction();

            $stmt = $pdo->prepare("
                CALL easy_pivot(
                    ?,
                    ?,
                    TRUE,
                    ?
                )
            ");

            $cursorName =
                'easy_pivot_workbench_cursor';

            $stmt->execute([
                $request['source_query'],
                $request['generated_json'],
                $cursorName
            ]);

            $stmt->closeCursor();

            $result =
                $pdo->query(
                    'FETCH ALL FROM "' .
                    $cursorName .
                    '"'
                )->fetch(PDO::FETCH_ASSOC);

            if (!$result ||
                !array_key_exists(
                    'Generated_SQL',
                    $result
                ))
            {
                $pdo->rollBack();

                throw new RuntimeException(
                    'Easy Pivot did not return generated SQL.'
                );
            }

            echo $result['Generated_SQL'];

            $pdo->commit();

            break;


        case 'oracle':

            /*
                Oracle returns the generated SQL through an
                implicit result set using DBMS_SQL.RETURN_RESULT.
            */

            $stmt = $pdo->prepare("
                BEGIN
                    easy_pivot(
                        :source_sql,
                        :json_configuration,
                        1
                    );
                END;
            ");

            $stmt->bindValue(
                ':source_sql',
                $request['source_query']
            );

            $stmt->bindValue(
                ':json_configuration',
                $request['generated_json']
            );

            $stmt->execute();

            $result =
                $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$result ||
                !array_key_exists(
                    'Generated_SQL',
                    $result
                ))
            {
                throw new RuntimeException(
                    'Easy Pivot did not return generated SQL.'
                );
            }

            echo $result['Generated_SQL'];

            break;


        case 'sqlserver':

            /*
                SQL Server returns generated source code as
                FULL_CODE when @generate_source_code_only = 1.
            */

            $stmt = $pdo->prepare("
                EXEC dbo.easy_pivot
                    @source_sql = ?,
                    @config = ?
            ");

            $stmt->execute([
                $request['source_query'],
                $request['generated_json']
            ]);

            $result =
                $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$result ||
                !array_key_exists(
                    'FULL_CODE',
                    $result
                ))
            {
                throw new RuntimeException(
                    'Easy Pivot did not return generated SQL.'
                );
            }

            echo $result['FULL_CODE'];

            break;


        default:

            throw new InvalidArgumentException(
                'Unsupported database type: ' .
                $databaseType
            );
    }
}
catch (Throwable $e)
{
    http_response_code(500);

    echo $e->getMessage();
}
