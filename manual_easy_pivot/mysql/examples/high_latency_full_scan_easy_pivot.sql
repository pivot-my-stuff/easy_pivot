SET @warnings = '';

-- Edit the SQL query below.

SET @user_sql = "

    SELECT
        db,
        CASE
            WHEN total_latency LIKE '% ms'
            THEN 'NORMAL'
            WHEN total_latency LIKE '% us'
            THEN 'NORMAL'
            WHEN total_latency LIKE '% ns'
            THEN 'NORMAL'
            WHEN total_latency LIKE '% ps'
            THEN 'NORMAL'
            ELSE 'HIGH'
        END AS `high_latency`,
        CASE
            WHEN full_scan = '*'
            THEN 'FULL_SCAN'
            ELSE 'INDEX'
        END AS `scan_type`,
        exec_count
    FROM
        sys.statement_analysis

";

-- Edit the Easy Pivot configuration below.

CALL easy_pivot
(
    @user_sql, '{


        "Group": [ "db" ],
        "Order": [ "ASC" ],
        "Pivot": [
             { "Pivot_Field": "high_latency", "Pivot_Type": "COUNT", "Pivot_Data": "exec_count", "Sort_Order": "DESC" }
            ,{ "Pivot_Field": "scan_type",    "Pivot_Type": "COUNT", "Pivot_Data": "exec_count", "Follows_Group": "db" }


]}', FALSE, @warnings); 


-- IF YOU REMOVE THE TWO DASHES FROM THE LAST LINE YOU
-- WILL GET TWO GRIDS.

-- The first Grid Tab contains your pivoted data.
-- The second Grid Tab contains warning messages if
-- Easy Pivot was installed with strict mode enabled.

-- SELECT @warnings AS Warning_Messages;
