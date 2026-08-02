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


-- IF YOU REMOVE THE TWO DASHES FROM THE LAST LINE YOU
-- WILL GET TWO GRIDS.

-- The first Grid Tab contains your pivoted data.
-- The second Grid Tab contains warning messages if
-- Easy Pivot was installed with strict mode enabled.

-- SELECT @warnings AS Warning_Messages;
