SET @warnings = '';

-- Edit the SQL query below.

SET @user_sql = "

    SELECT
        table_schema,
        table_name,
        rows_fetched,
        rows_inserted,
        rows_updated,
        rows_deleted
    FROM
        sys.schema_table_statistics
    WHERE
        table_schema IN ('easy_pivot', 'mysql', 'performance_schema', 'sys')

";

-- Edit the Easy Pivot configuration below.

CALL easy_pivot
(
    @user_sql, '{


        "Group": [ "table_schema" ],
        "Order": [ "ASC" ],
        "Pivot": [
             { "Pivot_Field": "table_name", "Pivot_Type": "SUM", "Pivot_Data": "rows_fetched",  "Sort_Order": "DESC" }
            ,{ "Pivot_Field": "table_name", "Pivot_Type": "SUM", "Pivot_Data": "rows_inserted", "Follows_Group": "table_schema" }
            ,{ "Pivot_Field": "table_name", "Pivot_Type": "SUM", "Pivot_Data": "rows_updated" }
            ,{ "Pivot_Field": "table_name", "Pivot_Type": "SUM", "Pivot_Data": "rows_deleted" }


]}', FALSE, @warnings); 


-- IF YOU REMOVE THE TWO DASHES FROM THE LAST LINE YOU
-- WILL GET TWO GRIDS.

-- The first Grid Tab contains your pivoted data.
-- The second Grid Tab contains warning messages if
-- Easy Pivot was installed with strict mode enabled.

-- SELECT @warnings AS Warning_Messages;
