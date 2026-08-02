SET @warnings = '';

-- Edit the SQL query below.

SET @user_sql = "

    SELECT
        table_schema,
        table_name,
        index_name,
        rows_selected
    FROM
        sys.schema_index_statistics

";

-- Edit the Easy Pivot configuration below.

CALL easy_pivot
(
    @user_sql, '{


        "Group": [ "table_schema", "table_name" ],
        "Order": [ "ASC", "ASC" ],
        "Pivot": [
            { "Pivot_Field": "index_name", "Pivot_Type": "SUM",   "Pivot_Data": "rows_selected", "Sort_Order": "DESC", "Follows_Group": "table_schema" }
           ,{ "Pivot_Field": "index_name", "Pivot_Type": "COUNT", "Pivot_Data": "rows_selected", "Follows_Group": "table_name" }


]}', FALSE, @warnings); 


-- IF YOU REMOVE THE TWO DASHES FROM THE LAST LINE YOU
-- WILL GET TWO GRIDS.

-- The first Grid Tab contains your pivoted data.
-- The second Grid Tab contains warning messages if
-- Easy Pivot was installed with strict mode enabled.

-- SELECT @warnings AS Warning_Messages;
