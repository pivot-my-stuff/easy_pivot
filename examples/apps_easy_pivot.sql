drop table if exists #app_data

create table #app_data (
	id INT,
	app_name VARCHAR(50),
	country_with_app VARCHAR(50),
	number_of_users INT,
    accepts_bitcoin INT
);

insert into #app_data (id, [app_name], country_with_app, number_of_users, accepts_bitcoin) values (1, 'Zathin', 'Kenya', 7013820, 1);
insert into #app_data (id, [app_name], country_with_app, number_of_users, accepts_bitcoin) values (2, 'Bamity', 'China', 1051400, 0);
insert into #app_data (id, [app_name], country_with_app, number_of_users, accepts_bitcoin) values (3, 'Flexidy', 'Hungary', 5518550, 1);
insert into #app_data (id, [app_name], country_with_app, number_of_users, accepts_bitcoin) values (4, 'Flexidy', 'Indonesia', 44351000, 1);
insert into #app_data (id, [app_name], country_with_app, number_of_users, accepts_bitcoin) values (5, 'Treeflex', 'Indonesia', 98299400, 0);
insert into #app_data (id, [app_name], country_with_app, number_of_users, accepts_bitcoin) values (6, 'Daltfresh', 'Russia', 89291800, 0);
insert into #app_data (id, [app_name], country_with_app, number_of_users, accepts_bitcoin) values (7, 'Matsoft', 'Russia', 41566200, 0);
insert into #app_data (id, [app_name], country_with_app, number_of_users, accepts_bitcoin) values (8, 'Toughjoyfax', 'China', 43801200, 0);
insert into #app_data (id, [app_name], country_with_app, number_of_users, accepts_bitcoin) values (9, 'Andalax', 'Portugal', 6246770, 1);
insert into #app_data (id, [app_name], country_with_app, number_of_users, accepts_bitcoin) values (10, 'Andalax', 'United States', 6997200, 1);

drop table if exists #app_data_table

select
     [app_name]
    ,country_with_app
    ,number_of_users
    ,case when accepts_bitcoin = 1 then 'Accepts Bitcoin' else 'No Bitcoin' end as accepts_bitcoin
into
    #app_data_table
from
    #app_data

/* Easy Pivot configuration section */

-- Change to 1 to print generated pivot code
DECLARE @generate_source_code_only AS BIT = 0

-- Change name of temp table "#car_prices" to name of your data source
DECLARE @source_table AS NVARCHAR(MAX)= '#app_data_table'

-- Change group & pivot field information to match your data source
--
-- One Group entry with comma-separated list of fields to group on
--
-- One Pivot section with one or more lines in it, separated by commas,
-- and first line has no comma in front of it; lines that follow do have them
DECLARE @config AS NVARCHAR(MAX) = '
[
    {
        "Group": ["country_with_app"],
        "Pivot": [
              {"Pivot_Field": "app_name", "Pivot_Data": "number_of_users", "Pivot_True": null, "Pivot_False": null, "Pivot_Type": "SUM", "Follows_Field": null, "Sort_Order": "ASC"}
             ,{"Pivot_Field": "accepts_bitcoin", "Pivot_Data": null, "Pivot_True": "*", "Pivot_False": "", "Pivot_Type": "MAX", "Follows_Field": "country_with_app", "Sort_Order": "ASC"}
        ]
    }
]
'

/* Perform Easy Pivot based on configuration section */
DROP TABLE IF EXISTS #group_table
SELECT g_table.[Group_Field]
INTO #group_table
FROM OPENJSON(@config) WITH ([Group] NVARCHAR(MAX) AS JSON) AS group_table
     CROSS APPLY
     OPENJSON(group_table.[Group]) WITH ([Group_Field] NVARCHAR(MAX) '$') AS g_table
DROP TABLE IF EXISTS #pivot_table
SELECT p_table.[Pivot_Field], p_table.[Pivot_Data], p_table.[Pivot_True], p_table.[Pivot_False], p_table.[Pivot_Type], p_table.[Follows_Field], p_table.[Sort_Order]
INTO #pivot_table
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
        [Sort_Order]      NVARCHAR(MAX)   '$.Sort_Order'
    ) AS p_table
DROP TABLE IF EXISTS #numeric_fields
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
DROP TABLE IF EXISTS #numeric_field_table
SELECT numeric_field_table.[name] INTO #numeric_field_table FROM OPENJSON(@numeric_fields_json) WITH ([name] NVARCHAR(MAX) '$.name') as numeric_field_table
DECLARE 
    @group_field AS NVARCHAR(MAX), @pivot_field AS NVARCHAR(MAX), @pivot_data AS NVARCHAR(MAX), @pivot_true AS NVARCHAR(MAX),
    @pivot_false AS NVARCHAR(MAX), @pivot_type AS NVARCHAR(MAX), @follows_field AS NVARCHAR(MAX), @sort_order AS NVARCHAR(MAX), @columns_sql AS NVARCHAR(MAX),
    @json AS NVARCHAR(MAX), @pivot_column_name AS NVARCHAR(MAX), @dynamic_pivot_query AS NVARCHAR(MAX) = '', @dynamic_select AS NVARCHAR(MAX) = '',
    @dynamic_from AS NVARCHAR(MAX) = '', @pivot_counter AS INT = 1, @numeric_flag AS INT, @comma_flag AS INT = 0, @comma_flag_FROM AS INT = 0,
    @linkage_for_pivots AS NVARCHAR(MAX) = '', @linkage_count AS INT = 0, @cnt AS INT = 0, @pass_counter AS INT = 0, @order_by AS NVARCHAR(MAX) = '',
    @pivot_group_name AS NVARCHAR(MAX) = '', @pivot_groups_for_FROM_section AS NVARCHAR(MAX) = ''
DECLARE group_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT Group_Field FROM #group_table
OPEN group_cursor
FETCH NEXT FROM group_cursor INTO @pivot_group_name
WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @comma_flag = 1
            BEGIN
                SET @pivot_groups_for_FROM_section = @pivot_groups_for_FROM_section + ',[' + @pivot_group_name + ']' + CHAR(13) + CHAR(10)
                SET @linkage_for_pivots = @linkage_for_pivots + 'AND template.[' + @pivot_group_name + '] = ep.[' + @pivot_group_name + ']' + CHAR(13) + CHAR(10)
                SET @order_by = @order_by  + ',ep.[' + @pivot_group_name + ']' + CHAR(13) + CHAR(10)
                SET @linkage_count = @linkage_count + 1
            END
        ELSE
            BEGIN
                SET @pivot_groups_for_FROM_section = @pivot_groups_for_FROM_section + '[' + @pivot_group_name + ']' + CHAR(13) + CHAR(10)
                SET @linkage_for_pivots = @linkage_for_pivots + ' ON template.[' + @pivot_group_name + '] = ep.[' + @pivot_group_name + ']' + CHAR(13) + CHAR(10)
                SET @order_by = @order_by + 'ORDER BY ' + CHAR(13) + CHAR(10) + 'ep.[' + @pivot_group_name + ']' + CHAR(13) + CHAR(10)
                SET @linkage_count = @linkage_count + 1
                SET @comma_flag = 1
            END

        FETCH NEXT FROM group_cursor INTO @pivot_group_name
    END
SET @comma_flag = 0
CLOSE group_cursor
DEALLOCATE group_cursor
SET @dynamic_select = @dynamic_select + 'SELECT' + CHAR(13) + CHAR(10)
SET @dynamic_from = @dynamic_from + 'FROM (SELECT DISTINCT' + CHAR(13) + CHAR(10)
SET @dynamic_from = @dynamic_from + @pivot_groups_for_FROM_section + 'FROM' + CHAR(13) + CHAR(10)
SET @dynamic_from = @dynamic_from + @source_table + ') AS ep' + CHAR(13) + CHAR(10)
BEGIN
    WHILE @pass_counter < 2
        BEGIN
            DECLARE group_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT Group_Field FROM #group_table
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
                    DECLARE pivot_cursor CURSOR FOR SELECT Pivot_Field, Pivot_Data, Pivot_True, Pivot_False, Pivot_Type, Follows_Field, Sort_Order FROM #pivot_table
                    OPEN pivot_cursor
                    FETCH NEXT FROM pivot_cursor INTO @pivot_field, @pivot_data, @pivot_true, @pivot_false, @pivot_type, @follows_field, @sort_order
                    WHILE @@FETCH_STATUS = 0
                        BEGIN
                            IF (@follows_field = @group_field AND @pass_counter = 0) OR
                                (@follows_field IS NULL AND @pass_counter = 1)
                                BEGIN
                                    IF (UPPER(@sort_order) <> 'ASC' AND UPPER(@sort_order) <> 'DESC') OR @sort_order IS NULL SET @sort_order = 'ASC'
                                    SET @columns_sql = N'SET @json_out = (SELECT tmp.[' + @pivot_field + '] AS PIVOT_FIELD FROM (SELECT DISTINCT [' + @pivot_field + '] FROM ' + @source_table + ') AS tmp ORDER BY [' + @pivot_field + '] ' + UPPER(@sort_order) + ' FOR JSON AUTO)'
                                    EXEC sp_executesql @columns_sql, N'@json_out NVARCHAR(MAX) OUTPUT', @json_out = @json OUTPUT;
                                    DECLARE pivot_columns_cursor CURSOR LOCAL FAST_FORWARD FOR
                                        SELECT j_table.[PIVOT_FIELD] FROM OPENJSON(@json) WITH ([PIVOT_FIELD] NVARCHAR(MAX) '$.PIVOT_FIELD') as j_table
                                    SET @numeric_flag = (SELECT COUNT(*) AS n FROM #pivot_table pt INNER JOIN #numeric_field_table nft ON nft.name = pt.Pivot_Data WHERE nft.name = @pivot_data)
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
                                                SET @dynamic_from = @dynamic_from + @pivot_type + '([' + @pivot_data + '])' + CHAR(13) + CHAR(10)
                                            ELSE
                                                SET @dynamic_from = @dynamic_from + @pivot_type + '([' + @pivot_field + '])' + CHAR(13) + CHAR(10)
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
                                                    IF @numeric_flag = 1
                                                        BEGIN
                                                            SET @dynamic_select = @dynamic_select + ',ISNULL(p' + CAST(@pivot_counter AS NVARCHAR) + '.[' + @pivot_column_name + '], 0) AS [' + @pivot_column_name + ']' + CHAR(13) + CHAR(10)
                                                        END
                                                    ELSE
                                                        BEGIN
                                                            SET @dynamic_select = @dynamic_select + ',p' + CAST(@pivot_counter AS NVARCHAR) + '.[' + @pivot_column_name + ']' + CHAR(13) + CHAR(10)
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

DECLARE @dynamic_sql AS NVARCHAR(MAX) = @dynamic_select + @dynamic_from + @order_by + CHAR(13) + CHAR(10)

IF @generate_source_code_only <> 0
    PRINT @dynamic_sql
ELSE
    EXEC (@dynamic_sql)
