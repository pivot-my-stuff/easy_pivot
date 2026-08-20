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

    /*
        Oracle is handled separately because the Easy Pivot Oracle
        procedure returns generated source code through
        DBMS_SQL.RETURN_RESULT.

        PDO_OCI can establish the connection, but it does not expose
        Oracle implicit result sets to PHP.  OCI8 does.
    */

    if ($databaseType === 'oracle')
    {
        if (!extension_loaded('oci8'))
        {
            throw new RuntimeException(
                'Oracle source-code retrieval requires the PHP OCI8 extension.'
            );
        }

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

        if ($username === '')
        {
            throw new InvalidArgumentException(
                'Database user name is required.'
            );
        }

        /*
            Use the same Easy Pivot Oracle connection model as
            database.php: host, port, and service name.
        */

        $connectString =
            sprintf(
                '//%s:%d/%s',
                $host,
                $port,
                $database
            );

        $ociConnection =
            @oci_connect(
                $username,
                $password,
                $connectString,
                'AL32UTF8'
            );

        if ($ociConnection === false)
        {
            $error = oci_error();

            throw new RuntimeException(
                'Oracle connection failed.' .
                "\n\n" .
                ($error['message'] ?? 'Unknown Oracle connection error.')
            );
        }

        try
        {
            /*
                Generate source code ONLY.

                The third Easy Pivot argument is deliberately 1.
                Do not change this to execute mode.
            */

            $sql =
                "
                BEGIN
                    easy_pivot(
                        :source_sql,
                        :json_configuration
                    );
                END;
                ";

            $stmt =
                @oci_parse(
                    $ociConnection,
                    $sql
                );

            if ($stmt === false)
            {
                $error = oci_error($ociConnection);

                throw new RuntimeException(
                    'Oracle statement preparation failed.' .
                    "\n\n" .
                    ($error['message'] ?? 'Unknown Oracle error.')
                );
            }

            $sourceSql =
                $request['source_query'];

            $jsonConfiguration =
                $request['generated_json'];

            if (!oci_bind_by_name(
                $stmt,
                ':source_sql',
                $sourceSql,
                -1,
                SQLT_CHR
            ))
            {
                $error = oci_error($stmt);

                throw new RuntimeException(
                    'Oracle source SQL bind failed.' .
                    "\n\n" .
                    ($error['message'] ?? 'Unknown Oracle error.')
                );
            }

            if (!oci_bind_by_name(
                $stmt,
                ':json_configuration',
                $jsonConfiguration,
                -1,
                SQLT_CHR
            ))
            {
                $error = oci_error($stmt);

                throw new RuntimeException(
                    'Oracle JSON configuration bind failed.' .
                    "\n\n" .
                    ($error['message'] ?? 'Unknown Oracle error.')
                );
            }

            if (!@oci_execute($stmt))
            {
                $error = oci_error($stmt);

                throw new RuntimeException(
                    'Oracle Easy Pivot execution failed.' .
                    "\n\n" .
                    ($error['message'] ?? 'Unknown Oracle error.')
                );
            }

            /*
                DBMS_SQL.RETURN_RESULT creates an implicit result set.
                OCI8 exposes it through oci_get_implicit_resultset().
            */

            $resultSet =
                oci_get_implicit_resultset($stmt);

            if ($resultSet === false)
            {
                throw new RuntimeException(
                    'Oracle Easy Pivot returned no implicit result set.'
                );
            }

            $result = false;

            while (($row = oci_fetch_array(
                $resultSet,
                OCI_ASSOC + OCI_RETURN_LOBS
            )) !== false)
            {
                /*
                    Oracle normally returns GENERATED_SQL in uppercase.
                    Accept either spelling so the PHP layer is not
                    dependent on identifier-case behavior.
                */

                foreach ($row as $column => $value)
                {
                    if (strcasecmp(
                        (string)$column,
                        'Generated_SQL'
                    ) === 0)
                    {
                        $result = $value;
                        break 2;
                    }
                }
            }

            if ($result === false ||
                $result === null)
            {
                throw new RuntimeException(
                    'Easy Pivot did not return generated SQL from Oracle.'
                );
            }

            /*
                Source-code-only mode returns the generated SQL text.
                Nothing returned by Oracle is executed here.
            */

            echo (string)$result;

            oci_free_statement($resultSet);
            oci_free_statement($stmt);
        }
        finally
        {
            oci_close($ociConnection);
        }

        exit;
    }


    /*
        All non-Oracle databases continue to use the existing PDO
        implementation.
    */

    $pdo =
        connectDatabase($connection);

    switch ($databaseType)
    {
        case 'mysql':

            $stmt = $pdo->prepare("
                CALL easy_pivot(
                    ?,
                    ?
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
                    ?
                )
            ");

            $cursorName =
                'easy_pivot_workbench_cursor';

            $stmt->execute([
                $request['source_query'],
                $request['generated_json']
            ]);

            /*
                The PostgreSQL Workbench procedure has only two parameters.
                The refcursor is an internal implementation detail with a
                fixed name known by both the procedure and this endpoint.
            */

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
