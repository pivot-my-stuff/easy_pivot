drop table if exists #furniture_sales

create table #furniture_sales (
	sales_person VARCHAR(5),
	date_of_sale DATE,
	sales_amount DECIMAL(6,2),
	item_sold VARCHAR(12),
	payment_method VARCHAR(12)
);
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Tom', '2021-11-15', 988.9, 'Dining Table', 'Store Credit');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Tom', '2021-11-15', 1147.48, 'Bed', 'Money Order');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Tom', '2021-11-18', 1193.17, 'Sofa', 'Credit Card');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Tom', '2021-11-18', 1346.51, 'Bed', 'Debit Card');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Susan', '2021-11-17', 1413.25, 'Cabinet', 'Money Order');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Amy', '2021-11-15', 1459.22, 'Cabinet', 'Cash');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Tom', '2021-11-17', 834.52, 'Dining Table', 'Check');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Amy', '2021-11-17', 1247.53, 'Recliner', 'Cash');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Amy', '2021-11-17', 1013.11, 'Recliner', 'Money Order');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Amy', '2021-11-19', 1101.41, 'Bed', 'Debit Card');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Tom', '2021-11-15', 1298.56, 'Recliner', 'Check');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Fred', '2021-11-15', 707.71, 'Cabinet', 'Debit Card');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Fred', '2021-11-17', 532.58, 'Bed', 'Check');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Tom', '2021-11-15', 963.79, 'Cabinet', 'Money Order');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Tom', '2021-11-16', 1172.59, 'Cabinet', 'Cash');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Tom', '2021-11-16', 796.09, 'Bed', 'Debit Card');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Fred', '2021-11-17', 1150.61, 'Sofa', 'Check');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Amy', '2021-11-19', 1494.3, 'Sofa', 'Debit Card');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Tom', '2021-11-18', 1085.05, 'Dining Table', 'Debit Card');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Fred', '2021-11-19', 1429.53, 'Bed', 'Credit Card');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Amy', '2021-11-17', 1330.29, 'Bed', 'Check');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Tom', '2021-11-18', 783.75, 'Sofa', 'Store Credit');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Tom', '2021-11-19', 609.51, 'Sofa', 'Cash');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Susan', '2021-11-15', 617.55, 'Bed', 'Cash');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Tom', '2021-11-19', 1209.37, 'Recliner', 'Money Order');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Tom', '2021-11-17', 1378.95, 'Bed', 'Money Order');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Amy', '2021-11-16', 873.33, 'Sofa', 'Store Credit');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Susan', '2021-11-17', 521.67, 'Sofa', 'Store Credit');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Amy', '2021-11-17', 1490.79, 'Recliner', 'Credit Card');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Amy', '2021-11-16', 972.15, 'Bed', 'Debit Card');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Amy', '2021-11-17', 782.43, 'Bed', 'Debit Card');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Tom', '2021-11-15', 600.47, 'Cabinet', 'Money Order');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Fred', '2021-11-18', 1133.92, 'Dining Table', 'Credit Card');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Tom', '2021-11-19', 743.01, 'Sofa', 'Credit Card');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Amy', '2021-11-18', 937.24, 'Cabinet', 'Credit Card');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Fred', '2021-11-16', 741.34, 'Cabinet', 'Store Credit');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Amy', '2021-11-19', 733.96, 'Recliner', 'Credit Card');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Fred', '2021-11-15', 1177.02, 'Dining Table', 'Money Order');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Tom', '2021-11-18', 1075.63, 'Bed', 'Money Order');
insert into #furniture_sales (sales_person, date_of_sale, sales_amount, item_sold, payment_method) values ('Tom', '2021-11-17', 1086.64, 'Recliner', 'Credit Card');

/* Easy Pivot configuration section */

-- Change to 1 to print generated pivot code
DECLARE @generate_source_code_only AS BIT = 0

-- Change name of temp table "#car_prices" to name of your data source
DECLARE @source_table AS NVARCHAR(MAX)= '#furniture_sales'

-- Change group & pivot field information to match your data source
--
-- One Group entry with comma-separated list of fields to group on
--
-- One Pivot section with one or more lines in it, separated by commas,
-- and first line has no comma in front of it; lines that follow do have them
DECLARE @config AS NVARCHAR(MAX) = '
[
    {
        "Group": ["sales_person"],
        "Pivot": [
             {"Pivot_Field": "date_of_sale", "Pivot_Data": "sales_amount", "Pivot_True": null, "Pivot_False": null, "Pivot_Type": "SUM", "Follows_Field": null, "Sort_Order": "DESC"}
            ,{"Pivot_Field": "payment_method", "Pivot_Data": null, "Pivot_True": "Yes", "Pivot_False": "No", "Pivot_Type": "MAX", "Follows_Field": null, "Sort_Order": "ASC"}
            ,{"Pivot_Field": "item_sold", "Pivot_Data": null, "Pivot_True": "Sold this", "Pivot_False": "", "Pivot_Type": "MAX", "Follows_Field": null, "Sort_Order": "ASC"}
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

