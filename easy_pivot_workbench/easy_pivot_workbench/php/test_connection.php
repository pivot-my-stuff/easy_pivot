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

    $connection = $request['connection'];

    $pdo = connectDatabase($connection);

    $databaseType =
        strtolower(
            trim(
                (string)($connection['databaseType'] ?? 'mysql')
            )
        );

    /*
        Get database version and, where supported, identify the
        current database user/schema.
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


        case 'oracle':

            /*
                Keep the connection test on PDO_OCI.  OCI8 is required
                only by generate.php because PDO_OCI does not expose
                Oracle implicit result sets returned by
                DBMS_SQL.RETURN_RESULT.
            */

            $stmt = $pdo->query("
                SELECT
                    SYS_CONTEXT('USERENV', 'SESSION_USER') AS session_user,
                    SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS current_schema,
                    SYS_CONTEXT('USERENV', 'SERVICE_NAME') AS service_name,
                    SYS_CONTEXT('USERENV', 'DB_NAME') AS db_name
                FROM dual
            ");

            $session = $stmt->fetch(PDO::FETCH_ASSOC);

            $versionStmt = $pdo->query("
                SELECT banner
                FROM v\$version
                WHERE banner LIKE 'Oracle Database%'
                  AND ROWNUM = 1
            ");

            $versionResult =
                $versionStmt->fetch(PDO::FETCH_ASSOC);

            $version =
                $versionResult['BANNER'] ??
                $versionResult['banner'] ??
                'unknown';

            $sessionUser =
                $session['SESSION_USER'] ??
                $session['session_user'] ??
                'unknown';

            $currentSchema =
                $session['CURRENT_SCHEMA'] ??
                $session['current_schema'] ??
                'unknown';

            $serviceName =
                $session['SERVICE_NAME'] ??
                $session['service_name'] ??
                'unknown';

            $dbName =
                $session['DB_NAME'] ??
                $session['db_name'] ??
                'unknown';

            echo 'Connection successful.' .
                 "\n\n" .
                 'Oracle version: ' .
                 $version .
                 "\n\n" .
                 'Session user: ' .
                 $sessionUser .
                 "\n" .
                 'Current schema: ' .
                 $currentSchema .
                 "\n" .
                 'Service: ' .
                 $serviceName .
                 "\n" .
                 'Database: ' .
                 $dbName .
                 "\n" .
                 'OCI8 extension: ' .
                 (extension_loaded('oci8') ? 'available' : 'NOT available');

            /*
                USER_OBJECTS checks the schema in which the procedure
                is actually owned.  This is the most useful test for
                the normal Easy Pivot installation model.
            */

            $procedureStmt = $pdo->query("
                SELECT
                    object_name,
                    object_type,
                    status
                FROM user_objects
                WHERE object_name = 'EASY_PIVOT'
                  AND object_type = 'PROCEDURE'
            ");

            $procedure =
                $procedureStmt->fetch(PDO::FETCH_ASSOC);

            echo "\n\n";

            if ($procedure)
            {
                $objectName =
                    $procedure['OBJECT_NAME'] ??
                    $procedure['object_name'] ??
                    'EASY_PIVOT';

                $objectType =
                    $procedure['OBJECT_TYPE'] ??
                    $procedure['object_type'] ??
                    'PROCEDURE';

                $status =
                    $procedure['STATUS'] ??
                    $procedure['status'] ??
                    'UNKNOWN';

                echo 'Easy Pivot procedure found.' .
                     "\n" .
                     'Procedure: ' .
                     $objectName .
                     "\n" .
                     'Type: ' .
                     $objectType .
                     "\n" .
                     'Status: ' .
                     $status;
            }
            else
            {
                /*
                    If the procedure is not owned by the current schema,
                    ALL_OBJECTS may still show an accessible procedure.
                */

                $accessibleStmt = $pdo->query("
                    SELECT
                        owner,
                        object_name,
                        object_type,
                        status
                    FROM all_objects
                    WHERE object_name = 'EASY_PIVOT'
                      AND object_type = 'PROCEDURE'
                    ORDER BY
                        CASE
                            WHEN owner = SYS_CONTEXT(
                                'USERENV',
                                'CURRENT_SCHEMA'
                            )
                            THEN 0
                            ELSE 1
                        END,
                        owner
                ");

                $accessible =
                    $accessibleStmt->fetch(PDO::FETCH_ASSOC);

                if ($accessible)
                {
                    $owner =
                        $accessible['OWNER'] ??
                        $accessible['owner'] ??
                        'unknown';

                    $objectName =
                        $accessible['OBJECT_NAME'] ??
                        $accessible['object_name'] ??
                        'EASY_PIVOT';

                    $status =
                        $accessible['STATUS'] ??
                        $accessible['status'] ??
                        'UNKNOWN';

                    echo 'Easy Pivot procedure found in another accessible schema.' .
                         "\n" .
                         'Owner: ' .
                         $owner .
                         "\n" .
                         'Procedure: ' .
                         $objectName .
                         "\n" .
                         'Status: ' .
                         $status;
                }
                else
                {
                    echo 'Easy Pivot procedure NOT found.';
                }
            }

            break;


        default:

            echo 'Connection successful.';

            break;
    }


    /*
        Check for Easy Pivot stored procedure for the databases that
        already have metadata checks.
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
