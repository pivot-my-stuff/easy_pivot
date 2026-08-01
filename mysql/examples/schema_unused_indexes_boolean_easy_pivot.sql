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


-- There will be two tabs for the Result Grids.

-- The first Result Grid Tab contains your pivoted data.
-- The second Result Grid Tab contains warning messages.

SELECT @warnings AS Warning_Messages;