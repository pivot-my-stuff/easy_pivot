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


-- There will be two tabs for the Result Grids.

-- The first Result Grid Tab contains your pivoted data.
-- The second Result Grid Tab contains warning messages.

SELECT @warnings AS Warning_Messages;