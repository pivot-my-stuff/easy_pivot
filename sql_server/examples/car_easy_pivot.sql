/*--------------------------------------------------------------

Example: car_easy_pivot.sql

Demonstrates:

    * Multiple aggregate pivots
    * Aggregate prefix naming
    * Group ordering
    * COUNT(), MIN(), MAX(), STDEV(), AVG(), and SUM()
    * Multiple pivots against the same source field
    * Large result sets containing many generated columns

--------------------------------------------------------------*/

SET NOCOUNT ON

DROP TABLE IF EXISTS #car_prices

SELECT *
INTO #car_prices
FROM
(
    VALUES
        ('USA', 'Ford', 'Fusion',     24000),
        ('USA', 'Ford', 'Mustang',    52000),
        ('USA', 'Ford', 'Explorer',   41000),
        ('USA', 'Ford', 'Bronco',     47000),

        ('USA', 'GM', 'Malibu',       26000),
        ('USA', 'GM', 'Corvette',     78000),
        ('USA', 'GM', 'Tahoe',        69000),
        ('USA', 'GM', 'Silverado',    61000),

        ('Japan', 'Toyota', 'Camry',  29000),
        ('Japan', 'Toyota', 'Supra',  58000),
        ('Japan', 'Toyota', 'RAV4',   36000),
        ('Japan', 'Toyota', 'Tacoma', 42000),

        ('Japan', 'Honda', 'Civic',   27000),
        ('Japan', 'Honda', 'Accord',  33000),
        ('Japan', 'Honda', 'Pilot',   47000),
        ('Japan', 'Honda', 'Ridgeline',46000),

        ('Germany', 'BMW', '330i',    51000),
        ('Germany', 'BMW', '540i',    69000),
        ('Germany', 'BMW', 'X5',      77000),
        ('Germany', 'BMW', 'M3',      85000),

        ('Germany', 'Mercedes', 'C300',55000),
        ('Germany', 'Mercedes', 'E350',67000),
        ('Germany', 'Mercedes', 'GLE',82000),
        ('Germany', 'Mercedes', 'S580',118000)
) AS data
(
    COUNTRY,
    COMPANY,
    MODEL,
    PRICE
)

/* Easy Pivot configuration section */

-- Change to 1 to print generated pivot code
DECLARE @generate_source_code_only AS BIT = 0

-- Change name of temp table "#car_prices" to name of your data source
DECLARE @source_table AS NVARCHAR(MAX)= '#car_prices'

-- Change group & pivot field information to match your data source
--
-- One Group entry with comma-separated list of fields to group on
--
-- One Pivot section with one or more lines in it, separated by commas,
-- and first line has no comma in front of it; lines that follow do have them
DECLARE @config AS NVARCHAR(MAX) = '
[
    {
        "Group": ["COUNTRY"],
        "Order": ["ASC"],
        "Pivot": [
             {"Pivot_Field": "COMPANY", "Pivot_Type": "Sum", "Pivot_Data": "PRICE"}
            ,{"Pivot_Field": "COMPANY", "Pivot_Type": "Avg", "Pivot_Data": "PRICE"}
            ,{"Pivot_Field": "COMPANY", "Pivot_Type": "Count", "Pivot_Data": "PRICE"}
            ,{"Pivot_Field": "COMPANY", "Pivot_Type": "Min", "Pivot_Data": "PRICE"}
            ,{"Pivot_Field": "COMPANY", "Pivot_Type": "Max", "Pivot_Data": "PRICE"}
            ,{"Pivot_Field": "COMPANY", "Pivot_Type": "Stdev", "Pivot_Data": "PRICE"}
            ,{"Pivot_Field": "COMPANY", "Pivot_Type": "Var", "Pivot_Data": "PRICE"}
            ,{"Pivot_Field": "COMPANY", "Pivot_Type": "VarP", "Pivot_Data": "PRICE"}
        ]
    }
]
'

/* Perform Easy Pivot based on configuration section */
DROP TABLE IF EXISTS #easypivot_group_table
SELECT TRIM(g_table.[Group_Field]) AS Group_Field
INTO #easypivot_group_table
FROM OPENJSON(@config) WITH ([Group] NVARCHAR(MAX) AS JSON) AS group_table
     CROSS APPLY
     OPENJSON(group_table.[Group]) WITH ([Group_Field] NVARCHAR(MAX) '$') AS g_table
DROP TABLE IF EXISTS #easypivot_order_table
SELECT TRIM(o_table.[Order_Field]) AS Order_Field
INTO #easypivot_order_table
FROM OPENJSON(@config) WITH ([Order] NVARCHAR(MAX) AS JSON) AS order_table
     CROSS APPLY
     OPENJSON(order_table.[Order]) WITH ([Order_Field] NVARCHAR(MAX) '$') AS o_table
DROP TABLE IF EXISTS #easypivot_pivot_table
SELECT p_table.[Pivot_Field], NULLIF(TRIM(p_table.[Pivot_Data]), '') AS [Pivot_Data], ISNULL(p_table.[Pivot_True], '') AS [Pivot_True], ISNULL(p_table.[Pivot_False], '') AS [Pivot_False], p_table.[Pivot_Type], COALESCE(NULLIF(TRIM(p_table.[Follows_Group]), ''), NULLIF(TRIM(p_table.[Follows_Field]), '')) AS [Follows_Field], ISNULL(NULLIF(TRIM([Sort_Order]),''),'ASC') AS [Sort_Order]
INTO #easypivot_pivot_table
FROM
    OPENJSON(@config) WITH (
        [Pivot] NVARCHAR(MAX) AS JSON
    ) AS pivot_table
    CROSS APPLY
    OPENJSON(pivot_table.[Pivot]) WITH (
        [Pivot_Field]     NVARCHAR(MAX)   '$.Pivot_Field',
        [Pivot_Data]      NVARCHAR(MAX)   '$.Pivot_Data',
        [Pivot_True]      NVARCHAR(MAX)   '$.Pivot_True',
        [Pivot_False]     NVARCHAR(MAX)   '$.Pivot_False',
        [Pivot_Type]      NVARCHAR(MAX)   '$.Pivot_Type',
        [Follows_Field]   NVARCHAR(MAX)   '$.Follows_Field',
        [Follows_Group]   NVARCHAR(MAX)   '$.Follows_Group',
        [Sort_Order]      NVARCHAR(MAX)   '$.Sort_Order'
    ) AS p_table
DROP TABLE IF EXISTS #easypivot_numeric_fields
DECLARE @numeric_fields_sql AS NVARCHAR(MAX) = N'
SET @numeric_fields_json_out = (
SELECT columns.name
FROM
    tempdb.sys.columns AS columns
    JOIN tempdb.sys.tables AS tables ON tables.object_id = columns.object_id
    JOIN sys.types AS types ON types.user_type_id = columns.user_type_id
WHERE
     tables.name LIKE ''' + @source_table + '%'' AND
     Lower(types.name) IN (''bit'', ''decimal'', ''numeric'', ''float'', ''real'',
                           ''int'', ''bigint'', ''smallint'', ''tinyint'', ''money'',
                           ''smallmoney'')
GROUP BY columns.name FOR JSON AUTO)'
DECLARE @numeric_fields_json AS NVARCHAR(MAX)
EXEC sp_executesql @numeric_fields_sql, N'@numeric_fields_json_out NVARCHAR(MAX) OUTPUT', @numeric_fields_json_out = @numeric_fields_json OUTPUT;
DROP TABLE IF EXISTS #easypivot_numeric_field_table
SELECT numeric_field_table.[name] INTO #easypivot_numeric_field_table FROM OPENJSON(@numeric_fields_json) WITH ([name] NVARCHAR(MAX) '$.name') as numeric_field_table
DECLARE
    @group_field AS NVARCHAR(MAX), @pivot_field AS NVARCHAR(MAX), @pivot_data AS NVARCHAR(MAX), @pivot_true AS NVARCHAR(MAX),
    @pivot_false AS NVARCHAR(MAX), @pivot_type AS NVARCHAR(MAX), @follows_field AS NVARCHAR(MAX), @sort_order AS NVARCHAR(MAX), @columns_sql AS NVARCHAR(MAX),
    @json AS NVARCHAR(MAX), @pivot_column_name AS NVARCHAR(MAX), @dynamic_pivot_query AS NVARCHAR(MAX) = '', @dynamic_select AS NVARCHAR(MAX) = '',
    @dynamic_from AS NVARCHAR(MAX) = '', @pivot_counter AS INT = 1, @numeric_flag AS INT, @comma_flag AS INT = 0, @comma_flag_FROM AS INT = 0,
    @linkage_for_pivots AS NVARCHAR(MAX) = '', @linkage_count AS INT = 0, @cnt AS INT = 0, @pass_counter AS INT = 0, @dynamic_order_by AS NVARCHAR(MAX) = '',
    @pivot_group_name AS NVARCHAR(MAX) = '', @pivot_order_name AS NVARCHAR(MAX) = '', @pivot_groups_for_FROM_section AS NVARCHAR(MAX) = ''
DECLARE group_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT Group_Field FROM #easypivot_group_table
DECLARE order_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT Order_Field FROM #easypivot_order_table
OPEN group_cursor
OPEN order_cursor
FETCH NEXT FROM group_cursor INTO @pivot_group_name
WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @pivot_order_name = ''
        FETCH NEXT FROM order_cursor INTO @pivot_order_name
        SET @pivot_order_name = ISNULL(@pivot_order_name, '')

        IF @comma_flag = 1
            BEGIN
                SET @pivot_groups_for_FROM_section = @pivot_groups_for_FROM_section + ',[' + @pivot_group_name + ']' + CHAR(13) + CHAR(10)
                SET @linkage_for_pivots = @linkage_for_pivots + 'AND template.[' + @pivot_group_name + '] = ep.[' + @pivot_group_name + ']' + CHAR(13) + CHAR(10)
                SET @dynamic_order_by = TRIM(@dynamic_order_by + ',ep.[' + @pivot_group_name + ']' + ' ' + @pivot_order_name) + CHAR(13) + CHAR(10)
                SET @linkage_count = @linkage_count + 1
            END
        ELSE
            BEGIN
                SET @pivot_groups_for_FROM_section = @pivot_groups_for_FROM_section + '[' + @pivot_group_name + ']' + CHAR(13) + CHAR(10)
                SET @linkage_for_pivots = @linkage_for_pivots + ' ON template.[' + @pivot_group_name + '] = ep.[' + @pivot_group_name + ']' + CHAR(13) + CHAR(10)
                SET @dynamic_order_by = @dynamic_order_by + 'ORDER BY ' + CHAR(13) + CHAR(10) + TRIM('ep.[' + @pivot_group_name + ']' + ' ' + @pivot_order_name) + CHAR(13) + CHAR(10)
                SET @linkage_count = @linkage_count + 1
                SET @comma_flag = 1
            END

        FETCH NEXT FROM group_cursor INTO @pivot_group_name
    END
SET @comma_flag = 0
CLOSE group_cursor
CLOSE order_cursor
DEALLOCATE group_cursor
DEALLOCATE order_cursor
SET @dynamic_select = @dynamic_select + 'SELECT' + CHAR(13) + CHAR(10)
SET @dynamic_from = @dynamic_from + 'FROM (SELECT DISTINCT' + CHAR(13) + CHAR(10)
SET @dynamic_from = @dynamic_from + @pivot_groups_for_FROM_section + 'FROM' + CHAR(13) + CHAR(10)
SET @dynamic_from = @dynamic_from + @source_table + ') AS ep' + CHAR(13) + CHAR(10)
BEGIN
    WHILE @pass_counter < 2
        BEGIN
            DECLARE group_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT Group_Field FROM #easypivot_group_table
            OPEN group_cursor;
            FETCH NEXT FROM group_cursor INTO @group_field
            WHILE @@FETCH_STATUS = 0
                BEGIN
                    IF @pass_counter = 0
                        BEGIN
                            IF @comma_flag = 1
                                SET @dynamic_select = @dynamic_select + ',ep.[' + @group_field + ']' + CHAR(13) + CHAR(10)
                            ELSE
                                BEGIN
                                    SET @dynamic_select = @dynamic_select + 'ep.[' + @group_field + ']' + CHAR(13) + CHAR(10)
                                    SET @comma_flag = 1
                                END
                        END
                    DECLARE pivot_cursor CURSOR FOR SELECT Pivot_Field, Pivot_Data, Pivot_True, Pivot_False, Pivot_Type, Follows_Field, Sort_Order FROM #easypivot_pivot_table
                    OPEN pivot_cursor
                    FETCH NEXT FROM pivot_cursor INTO @pivot_field, @pivot_data, @pivot_true, @pivot_false, @pivot_type, @follows_field, @sort_order
                    WHILE @@FETCH_STATUS = 0
                        BEGIN
                            IF (@follows_field = @group_field AND @pass_counter = 0) OR
                                ((@follows_field IS NULL OR TRIM(@follows_field) = '') AND @pass_counter = 1)
                                BEGIN
                                    IF (UPPER(@sort_order) <> 'ASC' AND UPPER(@sort_order) <> 'DESC') OR @sort_order IS NULL SET @sort_order = 'ASC'
                                    SET @columns_sql = N'SET @json_out = (SELECT tmp.[' + @pivot_field + '] AS PIVOT_FIELD FROM (SELECT DISTINCT [' + @pivot_field + '] FROM ' + @source_table + ') AS tmp ORDER BY [' + @pivot_field + '] ' + UPPER(@sort_order) + ' FOR JSON AUTO)'
                                    EXEC sp_executesql @columns_sql, N'@json_out NVARCHAR(MAX) OUTPUT', @json_out = @json OUTPUT;
                                    DECLARE pivot_columns_cursor CURSOR LOCAL FAST_FORWARD FOR
                                        SELECT j_table.[PIVOT_FIELD] FROM OPENJSON(@json) WITH ([PIVOT_FIELD] NVARCHAR(MAX) '$.PIVOT_FIELD') as j_table
                                    SET @numeric_flag = (SELECT COUNT(*) AS n FROM #easypivot_pivot_table pt INNER JOIN #easypivot_numeric_field_table nft ON nft.name = pt.Pivot_Data WHERE nft.name = @pivot_data)
                                    SET @comma_flag_FROM = 0
                                    OPEN pivot_columns_cursor
                                    FETCH NEXT FROM pivot_columns_cursor INTO @pivot_column_name
                                    IF @@FETCH_STATUS = 0
                                        BEGIN
                                            SET @dynamic_from = @dynamic_from + 'LEFT JOIN (' + CHAR(13) + CHAR(10)
                                            SET @dynamic_from = @dynamic_from + 'SELECT pivot_table.* FROM' + CHAR(13) + CHAR(10)
                                            SET @dynamic_from = @dynamic_from + '(' + CHAR(13) + CHAR(10)
                                            SET @dynamic_from = @dynamic_from + 'SELECT' + CHAR(13) + CHAR(10)
                                            SET @dynamic_from = @dynamic_from + @pivot_groups_for_FROM_section
                                            IF @pivot_data IS NOT NULL
                                                BEGIN
													IF @pivot_field = @pivot_data
	                                                    SET @dynamic_from = @dynamic_from  + ',[' + @pivot_field + ']' + CHAR(13) + CHAR(10)
													ELSE
														BEGIN
															SET @dynamic_from = @dynamic_from  + ',[' + @pivot_field + ']' + CHAR(13) + CHAR(10)
															SET @dynamic_from = @dynamic_from  + ',[' + @pivot_data + ']' + CHAR(13) + CHAR(10)
														END
                                                END
                                            ELSE
                                                SET @dynamic_from = @dynamic_from  + ',[' + @pivot_field + ']' + CHAR(13) + CHAR(10)
                                            SET @dynamic_from = @dynamic_from + 'FROM' + CHAR(13) + CHAR(10)
                                            SET @dynamic_from = @dynamic_from + @source_table + CHAR(13) + CHAR(10)
                                            SET @dynamic_from = @dynamic_from + ') p' + CHAR(13) + CHAR(10)
                                            SET @dynamic_from = @dynamic_from + 'PIVOT (' + CHAR(13) + CHAR(10)
                                            IF @pivot_data IS NOT NULL
                                                SET @dynamic_from = @dynamic_from + UPPER(@pivot_type) + '([' + @pivot_data + '])' + CHAR(13) + CHAR(10)
                                            ELSE
                                                SET @dynamic_from = @dynamic_from + UPPER(@pivot_type) + '([' + @pivot_field + '])' + CHAR(13) + CHAR(10)
                                            SET @dynamic_from = @dynamic_from + 'FOR [' + @pivot_field + ']' + ' IN (' + CHAR(13) + CHAR(10)
                                        END
                                    WHILE @@FETCH_STATUS = 0
                                        BEGIN
                                            IF @pivot_data IS NULL
                                                BEGIN
                                                    SET @dynamic_select = @dynamic_select + ',CASE WHEN ISNULL(p' + CAST(@pivot_counter AS NVARCHAR) + '.[' + @pivot_column_name + '], ''' + @pivot_false + ''') = ''' + @pivot_false + ''' THEN ''' + @pivot_false + ''' ELSE ''' + @pivot_true + ''' END AS [' + @pivot_column_name + ']' + CHAR(13) + CHAR(10)
                                                END
                                            ELSE
                                                BEGIN
                                                    IF @numeric_flag > 0
                                                        BEGIN
                                                            SET @dynamic_select = @dynamic_select + ',ISNULL(p' + CAST(@pivot_counter AS NVARCHAR) + '.[' + @pivot_column_name + '], 0) AS [' + @pivot_type + '_' + @pivot_column_name + ']' + CHAR(13) + CHAR(10)
                                                        END
                                                    ELSE
                                                        BEGIN
                                                            SET @dynamic_select = @dynamic_select + ',ISNULL(p' + CAST(@pivot_counter AS NVARCHAR) + '.[' + @pivot_column_name + '],'''') AS [' + @pivot_type + '_' + @pivot_column_name + ']' + CHAR(13) + CHAR(10)
                                                        END
                                                END
                                            IF @comma_flag_FROM = 1
                                                SET @dynamic_from = @dynamic_from + ',[' + @pivot_column_name + ']' + CHAR(13) + CHAR(10)
                                            ELSE
                                                BEGIN
                                                    SET @dynamic_from = @dynamic_from + '[' + @pivot_column_name + ']' + CHAR(13) + CHAR(10)
                                                    SET @comma_flag_FROM = 1
                                                END
                                            FETCH NEXT FROM pivot_columns_cursor INTO @pivot_column_name
                                        END
                                    CLOSE pivot_columns_cursor
                                    DEALLOCATE pivot_columns_cursor
                                    SET @dynamic_from = @dynamic_from + ')' + CHAR(13) + CHAR(10)
                                    SET @dynamic_from = @dynamic_from + ') AS pivot_table' + CHAR(13) + CHAR(10)
                                    SET @dynamic_from = @dynamic_from + ') AS p' + CAST(@pivot_counter AS NVARCHAR)
                                    SET @dynamic_from = @dynamic_from + REPLACE(@linkage_for_pivots, 'template', 'p' + CAST(@pivot_counter AS NVARCHAR))
                                    SET @pivot_counter = @pivot_counter + 1
                                END
                            FETCH NEXT FROM pivot_cursor INTO @pivot_field, @pivot_data, @pivot_true, @pivot_false, @pivot_type, @follows_field, @sort_order
                        END
                    CLOSE pivot_cursor
                    DEALLOCATE pivot_cursor
                    IF @pass_counter = 1 BREAK
                    FETCH NEXT FROM group_cursor INTO @group_field
                END
            CLOSE group_cursor;
            DEALLOCATE group_cursor;
            SET @pass_counter = @pass_counter + 1
        END
END

DECLARE @dynamic_sql AS NVARCHAR(MAX) = @dynamic_select + @dynamic_from + @dynamic_order_by + CHAR(13) + CHAR(10)

IF @generate_source_code_only <> 0
  BEGIN
    PRINT @dynamic_sql
    SELECT @dynamic_sql AS FULL_CODE
  END
ELSE
    EXEC (@dynamic_sql)
