SET @warnings = '';

-- Edit the SQL query below.

SET @user_sql = "

    SELECT
        object_schema,
        index_name,
        object_name
    FROM
        sys.schema_unused_indexes

";

-- Edit the Easy Pivot configuration below.

CALL easy_pivot
(
    @user_sql, '{


        "Group": [ "index_name" ],
        "Order": [ "ASC" ],
        "Pivot": [
             { "Pivot_Field": "object_name", "Pivot_Type": "MAX", "Pivot_True": "YES", "Sort_Order": "DESC" }


]}', FALSE, @warnings); 


-- IF YOU REMOVE THE TWO DASHES FROM THE LAST LINE YOU
-- WILL GET TWO GRIDS.

-- The first Grid Tab contains your pivoted data.
-- The second Grid Tab contains warning messages if
-- Easy Pivot was installed with strict mode enabled.

-- SELECT @warnings AS Warning_Messages;
