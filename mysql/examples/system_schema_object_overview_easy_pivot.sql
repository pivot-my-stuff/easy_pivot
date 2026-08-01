SET @warnings = '';

-- Edit the SQL query below.

SET @user_sql = "

    SELECT
        db,
        object_type,
        count
    FROM
        sys.schema_object_overview

";

-- Edit the Easy Pivot configuration below.

CALL easy_pivot
(
    @user_sql, '{


        "Group": [ "db" ],
        "Order": [ "ASC" ],
        "Pivot": [
            { "Pivot_Field": "object_type", "Pivot_Type": "SUM", "Pivot_Data": "count", "Sort_Order": "DESC" }
           ,{ "Pivot_Field": "object_type", "Pivot_Type": "COUNT", "Pivot_Data": "count", "Follows_Group": "db" }


]}', FALSE, @warnings); 


-- There will be two tabs for the Result Grids.

-- The first Result Grid Tab contains your pivoted data.
-- The second Result Grid Tab contains warning messages.

SELECT @warnings AS Warning_Messages;