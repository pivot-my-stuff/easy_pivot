DELIMITER $$

DROP PROCEDURE IF EXISTS easy_pivot$$

CREATE PROCEDURE easy_pivot
(
    IN  p_user_sql LONGTEXT,
    IN  p_json_configuration JSON,
    IN  p_generate_source_code_only BOOLEAN,
    OUT p_warning_messages LONGTEXT
)

BEGIN

    -- ------------------------------------------------------------------------
    -- EASY PIVOT ENGINE
    -- ------------------------------------------------------------------------

	DECLARE v_strict_pivot_validation BOOLEAN DEFAULT FALSE;

    -- ------------------------------------------------------------------------
    -- Dynamic SQL
    -- ------------------------------------------------------------------------

    DECLARE v_pivot_discovery_sql      LONGTEXT;

    DECLARE v_dynamic_select           LONGTEXT DEFAULT '';
    DECLARE v_dynamic_from             LONGTEXT DEFAULT '';
    DECLARE v_dynamic_order_by         LONGTEXT DEFAULT '';
    DECLARE v_final_sql                LONGTEXT;

    -- ------------------------------------------------------------------------
    -- Current Pivot
    -- ------------------------------------------------------------------------

    DECLARE v_pivot_field              VARCHAR(255);
    DECLARE v_pivot_type               VARCHAR(255);
    DECLARE v_pivot_data               VARCHAR(255);
    DECLARE v_pivot_value              LONGTEXT;

    -- ------------------------------------------------------------------------
    -- Counts
    -- ------------------------------------------------------------------------

    DECLARE v_pivot_count              INT DEFAULT 0;
    DECLARE v_group_count              INT DEFAULT 0;
    DECLARE v_pivot_value_count        INT DEFAULT 0;

    -- ------------------------------------------------------------------------
    -- Metadata Arrays
    -- ------------------------------------------------------------------------

    DECLARE v_group_fields             JSON;
    DECLARE v_group_orders             JSON;

    DECLARE v_pivot_fields             JSON;
    DECLARE v_pivot_types              JSON;
    DECLARE v_pivot_datas              JSON;

    DECLARE v_pivot_trues              JSON;
    DECLARE v_pivot_falses             JSON;

    DECLARE v_pivot_follows            JSON;
    DECLARE v_pivot_sort_orders        JSON;

    DECLARE v_pivot_values             JSON;
    DECLARE v_current_pivot_values     JSON;

    DECLARE v_numeric_flags            JSON;

    DECLARE v_metadata_view_name       VARCHAR(255);
    DECLARE v_current_pivot            INT;

    DECLARE v_metadata_columns JSON;
    DECLARE v_metadata_types   JSON;

    -- ------------------------------------------------------------------------
    -- JSON Objects
    -- ------------------------------------------------------------------------

    DECLARE v_json_group               JSON;
    DECLARE v_json_pivot               JSON;
    DECLARE v_json_item                JSON;

    -- ------------------------------------------------------------------------
    -- Working Variables
    -- ------------------------------------------------------------------------

    DECLARE v_sql                      LONGTEXT;
    DECLARE v_column_name              VARCHAR(255);
    DECLARE v_value                    LONGTEXT;

    DECLARE i                          INT;
    DECLARE j                          INT;
    DECLARE k                          INT;

    DECLARE record_count               INT;

    DECLARE v_detected_type            VARCHAR(64);
	DECLARE v_group_field              VARCHAR(255);
	DECLARE v_group_order              VARCHAR(10);
    DECLARE v_follows_group            VARCHAR(255);
    DECLARE v_pivot_true               LONGTEXT;
    DECLARE v_pivot_false              LONGTEXT;
    DECLARE v_debug                    LONGTEXT DEFAULT '';
    DECLARE v_warning_messages         LONGTEXT DEFAULT '';

    -- ------------------------------------------------------------------------
    -- Engine Debug Mode
    -- ------------------------------------------------------------------------

    DECLARE v_debug_mode               BOOLEAN DEFAULT FALSE;

    -- ------------------------------------------------------------------------
    -- Engine Variables
    -- ------------------------------------------------------------------------

    DECLARE pivot_number               INT;
    DECLARE group_number               INT;
    DECLARE join_group_number          INT;
    DECLARE chip_number                INT;
    DECLARE existing_chip              INT;

    DECLARE v_duplicate_found          BOOLEAN;
    DECLARE v_first_group              BOOLEAN;
    DECLARE v_first_pivot_value        INT;
    DECLARE v_pivot_alias              INT;
    DECLARE v_sql_pivot_type           VARCHAR(64);

    DECLARE v_output                   LONGTEXT;

    DECLARE pass_counter               INT;

    DECLARE v_skip_chip                BOOLEAN DEFAULT FALSE;

    -- ----------------------------------------------------------------------------
    -- Initialize Engine
    -- ----------------------------------------------------------------------------

    SET v_dynamic_select   = '';
    SET v_dynamic_from     = '';
    SET v_dynamic_order_by = '';
    SET v_final_sql        = '';

    SET v_group_fields       = JSON_ARRAY();
    SET v_group_orders       = JSON_ARRAY();

    SET v_pivot_fields       = JSON_ARRAY();
    SET v_pivot_types        = JSON_ARRAY();
    SET v_pivot_datas        = JSON_ARRAY();

    SET v_pivot_trues        = JSON_ARRAY();
    SET v_pivot_falses       = JSON_ARRAY();

    SET v_pivot_follows      = JSON_ARRAY();
    SET v_pivot_sort_orders  = JSON_ARRAY();

    SET v_pivot_values       = JSON_ARRAY();
    SET v_current_pivot_values = JSON_ARRAY();

    SET v_numeric_flags      = JSON_ARRAY();

    SET v_group_count        = 0;
    SET v_pivot_count        = 0;
    SET v_pivot_value_count  = 0;

    -- ----------------------------------------------------------------------------
    -- Parse JSON Configuration
    -- ----------------------------------------------------------------------------

    SET i = 0;

    WHILE i < JSON_LENGTH(p_json_configuration)
    DO

        SET v_json_group =
            JSON_EXTRACT(
                p_json_configuration,
                CONCAT('$[', i, ']')
            );

        -- ------------------------------------------------------------------------
        -- Group Fields
        -- ------------------------------------------------------------------------

        SET j = 0;

        WHILE j < JSON_LENGTH(JSON_EXTRACT(v_json_group, '$.Group'))
        DO

            SET v_group_fields =
                JSON_ARRAY_APPEND(
                    v_group_fields,
                    '$',
                    TRIM(
                        JSON_UNQUOTE(
                            JSON_EXTRACT(
                                v_json_group,
                                CONCAT('$.Group[', j, ']')
                            )
                        )
                    )
                );

            SET v_group_count = v_group_count + 1;

            SET j = j + 1;

        END WHILE;


        -- ------------------------------------------------------------------------
        -- Group Ordering
        -- ------------------------------------------------------------------------

        IF JSON_CONTAINS_PATH(v_json_group, 'one', '$.Order')
        THEN

            SET j = 0;

            WHILE j < JSON_LENGTH(JSON_EXTRACT(v_json_group, '$.Order'))
            DO

                SET v_group_orders =
                    JSON_ARRAY_APPEND(
                        v_group_orders,
                        '$',
                        UPPER(
                            TRIM(
                                JSON_UNQUOTE(
                                    JSON_EXTRACT(
                                        v_json_group,
                                        CONCAT('$.Order[', j, ']')
                                    )
                                )
                            )
                        )
                    );

                SET j = j + 1;

            END WHILE;

        END IF;


        -- ------------------------------------------------------------------------
        -- Pivot Definitions
        -- ------------------------------------------------------------------------

        SET j = 0;

        WHILE j < JSON_LENGTH(JSON_EXTRACT(v_json_group, '$.Pivot'))
        DO

            SET v_json_pivot =
                JSON_EXTRACT(
                    v_json_group,
                    CONCAT('$.Pivot[', j, ']')
                );

            SET v_pivot_fields =
                JSON_ARRAY_APPEND(
                    v_pivot_fields,
                    '$',
                    TRIM(
                        JSON_UNQUOTE(
                            JSON_EXTRACT(
                                v_json_pivot,
                                '$.Pivot_Field'
                            )
                        )
                    )
                );

            SET v_pivot_types =
                JSON_ARRAY_APPEND(
                    v_pivot_types,
                    '$',
                    TRIM(
                        JSON_UNQUOTE(
                            JSON_EXTRACT(
                                v_json_pivot,
                                '$.Pivot_Type'
                            )
                        )
                    )
                );

            SET v_pivot_datas =
                JSON_ARRAY_APPEND(
                    v_pivot_datas,
                    '$',
                    NULLIF
                    (
                        TRIM(
                            JSON_UNQUOTE(
                                JSON_EXTRACT(
                                    v_json_pivot,
                                    '$.Pivot_Data'
                                )
                            )
                        ),
                        ''
                    )
                );

            SET v_pivot_trues =
                JSON_ARRAY_APPEND(
                    v_pivot_trues,
                    '$',
                    COALESCE(
                        JSON_UNQUOTE(
                            JSON_EXTRACT(
                                v_json_pivot,
                                '$.Pivot_True'
                            )
                        ),
                        ''
                    )
                );

            SET v_pivot_falses =
                JSON_ARRAY_APPEND(
                    v_pivot_falses,
                    '$',
                    COALESCE(
                        JSON_UNQUOTE(
                            JSON_EXTRACT(
                                v_json_pivot,
                                '$.Pivot_False'
                            )
                        ),
                        ''
                    )
                );

            SET v_pivot_follows =
                JSON_ARRAY_APPEND(
                    v_pivot_follows,
                    '$',
                    TRIM(
                        COALESCE(
                            JSON_UNQUOTE(
                                JSON_EXTRACT(
                                    v_json_pivot,
                                    '$.Follows_Group'
                                )
                            ),
                            JSON_UNQUOTE(
                                JSON_EXTRACT(
                                    v_json_pivot,
                                    '$.Follows_Field'
                                )
                            ),
                            ''
                        )
                    )
                );

            SET v_pivot_sort_orders =
                JSON_ARRAY_APPEND(
                    v_pivot_sort_orders,
                    '$',
                    UPPER(
                        TRIM(
                            COALESCE(
                                JSON_UNQUOTE(
                                    JSON_EXTRACT(
                                        v_json_pivot,
                                        '$.Sort_Order'
                                    )
                                ),
                                'ASC'
                            )
                        )
                    )
                );

            SET v_pivot_count = v_pivot_count + 1;

            SET j = j + 1;

        END WHILE;

        SET i = i + 1;

    END WHILE;

    IF v_debug_mode THEN

        SET v_debug =
        CONCAT(
            'Group Fields:\n',
            JSON_PRETTY(v_group_fields),

            '\n\nPivot Fields:\n',
            COALESCE(JSON_PRETTY(v_pivot_fields), '<NULL>'),

            '\n\nPivot Value Arrays:\n',
            COALESCE(JSON_PRETTY(v_pivot_values), '<NULL>'),

            '\n\nPivot Data:\n',
            COALESCE(JSON_PRETTY(v_pivot_datas), '<NULL>'),

            '\n\nPivot True:\n',
            COALESCE(JSON_PRETTY(v_pivot_trues), '<NULL>'),

            '\n\nPivot False:\n',
            COALESCE(JSON_PRETTY(v_pivot_falses), '<NULL>')
        );

    END IF;    

    -- ----------------------------------------------------------------------------
    -- Discover Result Set Metadata
    -- ----------------------------------------------------------------------------

    SET v_metadata_view_name =
        CONCAT(
            'ep_metadata_',
            CONNECTION_ID(),
            '_',
            UUID_SHORT()
        );

    -- ------------------------------------------------------------------------
    -- Create temporary metadata view
    -- ------------------------------------------------------------------------

    SET @sql =
        CONCAT(
            'CREATE VIEW `',
            v_metadata_view_name,
            '` AS ',
            p_user_sql
        );

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- ------------------------------------------------------------------------
    -- Read metadata into JSON arrays
    -- ------------------------------------------------------------------------

    SET @sql =
        CONCAT(
            'SELECT ',
            'JSON_ARRAYAGG(COLUMN_NAME),',
            'JSON_ARRAYAGG(LOWER(DATA_TYPE)) ',
            'INTO ',
            '@metadata_columns,',
            '@metadata_types ',
            'FROM INFORMATION_SCHEMA.COLUMNS ',
            'WHERE TABLE_SCHEMA = DATABASE() ',
            'AND TABLE_NAME = ',
            QUOTE(v_metadata_view_name),
            ' ORDER BY ORDINAL_POSITION'
        );

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET v_metadata_columns = @metadata_columns;
    SET v_metadata_types   = @metadata_types;

    -- ------------------------------------------------------------------------
    -- Remove metadata view immediately
    -- ------------------------------------------------------------------------

    SET @sql =
        CONCAT(
            'DROP VIEW `',
            v_metadata_view_name,
            '`'
        );

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- ----------------------------------------------------------------------------
    -- Determine Pivot Data Types
    -- ----------------------------------------------------------------------------

    IF v_pivot_count > 0 THEN

        SET pivot_number = 0;

        WHILE pivot_number < JSON_LENGTH(v_pivot_fields)
        DO

            IF JSON_TYPE(
                JSON_EXTRACT(
                    v_pivot_datas,
                    CONCAT('$[', pivot_number, ']')
                )
            ) = 'NULL'
            THEN
                SET v_pivot_data = NULL;
            ELSE
                SET v_pivot_data =
                    JSON_UNQUOTE(
                        JSON_EXTRACT(
                            v_pivot_datas,
                            CONCAT('$[', pivot_number, ']')
                        )
                    );
            END IF;

            SET v_numeric_flags =
                JSON_ARRAY_APPEND(
                    v_numeric_flags,
                    '$',
                    0
                );

            IF v_pivot_data IS NOT NULL THEN

                SET k = 0;

                metadata_lookup:
                WHILE k < JSON_LENGTH(v_metadata_columns)
                DO

                    SET v_column_name =
                        JSON_UNQUOTE(
                            JSON_EXTRACT(
                                v_metadata_columns,
                                CONCAT('$[', k, ']')
                            )
                        );

                    IF v_column_name = v_pivot_data THEN

                        SET v_detected_type =
                            LOWER(
                                JSON_UNQUOTE(
                                    JSON_EXTRACT(
                                        v_metadata_types,
                                        CONCAT('$[', k, ']')
                                    )
                                )
                            );

                        IF v_detected_type IN
                        (
                            'tinyint',
                            'smallint',
                            'mediumint',
                            'int',
                            'integer',
                            'bigint',
                            'decimal',
                            'numeric',
                            'float',
                            'double',
                            'real'
                        )
                        THEN

                            SET v_numeric_flags =
                                JSON_SET(
                                    v_numeric_flags,
                                    CONCAT('$[', pivot_number, ']'),
                                    1
                                );

                        END IF;

                        LEAVE metadata_lookup;

                    END IF;

                    SET k = k + 1;

                END WHILE;

            END IF;

            SET pivot_number = pivot_number + 1;

        END WHILE;

    END IF;

    -- ----------------------------------------------------------------------------
    -- Discover Distinct Pivot Values
    -- ----------------------------------------------------------------------------

    SET v_pivot_value_count = 0;

    SET pivot_number = 0;

    WHILE pivot_number < JSON_LENGTH(v_pivot_fields)
    DO

        SET v_pivot_field =
            JSON_UNQUOTE(
                JSON_EXTRACT(
                    v_pivot_fields,
                    CONCAT('$[', pivot_number, ']')
                )
            );

        SET @sql =
            CONCAT(
                'SELECT JSON_ARRAYAGG(`',
                REPLACE(v_pivot_field,'`','``'),
                '`) ',
                'INTO @pivot_values ',
                'FROM (',
                'SELECT DISTINCT `',
                REPLACE(v_pivot_field,'`','``'),
                '` ',
                'FROM (',
                p_user_sql,
                ') ep_source ',
                'ORDER BY `',
                REPLACE(v_pivot_field,'`','``'),
                '` ',
                CASE
                    WHEN UPPER(
                        JSON_UNQUOTE(
                            JSON_EXTRACT(
                                v_pivot_sort_orders,
                                CONCAT('$[', pivot_number, ']')
                            )
                        )
                    )
                    IN ('ASC','DESC')
                    THEN
                        UPPER(
                            JSON_UNQUOTE(
                                JSON_EXTRACT(
                                    v_pivot_sort_orders,
                                    CONCAT('$[', pivot_number, ']')
                                )
                            )
                        )
                    ELSE 'ASC'
                END,
                ') x'
            );

        PREPARE stmt FROM @sql;

        EXECUTE stmt;

        DEALLOCATE PREPARE stmt;

        IF v_debug_mode THEN

            SET v_debug =
            CONCAT(
                v_debug,
                '\n\n',
                'Discovery SQL:',
                '\n',
                @sql,
                '\n\nPivot Values:',
                '\n',
                COALESCE(JSON_PRETTY(@pivot_values), '<SQL NULL>')
            );

        END IF;

        SET v_pivot_values =
            JSON_ARRAY_APPEND
            (
                v_pivot_values,
                '$',
                JSON_EXTRACT(@pivot_values, '$')
            );

        SET v_pivot_value_count =
            v_pivot_value_count
            + JSON_LENGTH(@pivot_values);

        SET pivot_number = pivot_number + 1;

    END WHILE;

    IF v_debug_mode THEN

        SET v_debug = CONCAT(
            v_debug,
            '\n\nPivot Value Arrays:\n',
            COALESCE(JSON_PRETTY(v_pivot_values), '<SQL NULL>')
        );

    END IF;

    -- ----------------------------------------------------------------------------
    -- Build Dynamic SELECT and FROM
    -- ----------------------------------------------------------------------------

    SET v_pivot_alias = 1;
    SET v_first_pivot_value = 1;

    -- ------------------------------------------------------------------------
    -- SELECT HEADER
    -- ------------------------------------------------------------------------

    SET v_dynamic_select = 'SELECT';

    -- ------------------------------------------------------------------------
    -- FROM HEADER
    -- ------------------------------------------------------------------------

    SET v_dynamic_from =
        'FROM\n(\n'
        '    SELECT DISTINCT';

    SET group_number = 0;

    WHILE group_number < JSON_LENGTH(v_group_fields)
    DO

        IF group_number > 0 THEN

            SET v_dynamic_from =
                CONCAT(
                    v_dynamic_from,
                    ','
                );

        END IF;

        SET v_dynamic_from =
            CONCAT(
                v_dynamic_from,
                '\n        `',
                JSON_UNQUOTE(
                    JSON_EXTRACT(
                        v_group_fields,
                        CONCAT('$[', group_number, ']')
                    )
                ),
                '`'
            );

        SET group_number = group_number + 1;

    END WHILE;

    SET v_dynamic_from =
        CONCAT(
            v_dynamic_from,
            '\n    FROM\n',
            '    (\n',
            p_user_sql,
            '\n',
            '    ) ep_source\n',
            ') ep\n'
        );

    -- ----------------------------------------------------------------------------
    -- TWO-PASS EASY PIVOT PROCESSING
    -- ----------------------------------------------------------------------------

    SET pass_counter = 0;

    -- ----------------------------------------------------------------------------
    -- Two-Pass Easy Pivot Processing
    -- ----------------------------------------------------------------------------

    WHILE pass_counter <= 1
    DO

        -- ------------------------------------------------------------
        -- Emit current group fields
        -- ------------------------------------------------------------

        IF pass_counter = 0 THEN

            IF v_dynamic_select <> 'SELECT' THEN

                SET v_dynamic_select =
                    CONCAT(
                        v_dynamic_select,
                        ','
                    );

            END IF;

        END IF;

        SET group_number = 0;

        WHILE group_number < JSON_LENGTH(v_group_fields)
        DO

            IF pass_counter = 0 THEN

                IF group_number > 0 THEN

                    SET v_dynamic_select =
                        CONCAT(
                            v_dynamic_select,
                            ','
                        );

                END IF;

                SET v_dynamic_select =
                    CONCAT(
                        v_dynamic_select,
                        '\n    ep.`',
                        JSON_UNQUOTE(
                            JSON_EXTRACT(
                                v_group_fields,
                                CONCAT('$[', group_number, ']')
                            )
                        ),
                        '`'
                    );

            END IF;

            -- --------------------------------------------------------
            -- Process each pivot definition
            -- --------------------------------------------------------

            SET pivot_number = 0;

            pivot_loop:
            WHILE pivot_number < JSON_LENGTH(v_pivot_fields)
            DO

                -- ----------------------------------------------------
                -- Load current pivot metadata
                -- ----------------------------------------------------

                SET v_pivot_field =
                    JSON_UNQUOTE(
                        JSON_EXTRACT(
                            v_pivot_fields,
                            CONCAT('$[', pivot_number, ']')
                        )
                    );

                SET v_pivot_type =
                    JSON_UNQUOTE(
                        JSON_EXTRACT(
                            v_pivot_types,
                            CONCAT('$[', pivot_number, ']')
                        )
                    );

				SET v_pivot_type = TRIM(v_pivot_type);

				IF v_pivot_type IS NOT NULL
				AND
				(
					   v_pivot_type = ''
					OR v_pivot_type = 'null'
				)
				THEN
					SET v_pivot_type = NULL;
				END IF;

                IF JSON_TYPE(
                    JSON_EXTRACT(
                        v_pivot_datas,
                        CONCAT('$[', pivot_number, ']')
                    )
                ) = 'NULL'
                THEN
                    SET v_pivot_data = NULL;
                ELSE
                    SET v_pivot_data =
                        JSON_UNQUOTE(
                            JSON_EXTRACT(
                                v_pivot_datas,
                                CONCAT('$[', pivot_number, ']')
                            )
                        );
                END IF;

                SET v_follows_group =
                    TRIM(
                        COALESCE(
                            JSON_UNQUOTE(
                                JSON_EXTRACT(
                                    v_pivot_follows,
                                    CONCAT('$[', pivot_number, ']')
                                )
                            ),
                            ''
                        )
                    );

                -- ----------------------------------------------------
                -- Translate aggregate name
                -- ----------------------------------------------------

				SET v_sql_pivot_type =
					CASE
						WHEN v_pivot_type IS NULL
						THEN 'MAX'
						ELSE UPPER(v_pivot_type)
					END;

                IF v_sql_pivot_type = 'STDEV' THEN

                    SET v_sql_pivot_type = 'STDDEV';

                ELSEIF v_sql_pivot_type = 'VAR' THEN

                    SET v_sql_pivot_type = 'VAR_SAMP';

                ELSEIF v_sql_pivot_type = 'VARP' THEN

                    SET v_sql_pivot_type = 'VAR_POP';

                END IF;

                -- --------------------------------------------------------
                -- Iterate cached pivot values
                -- --------------------------------------------------------

                IF(
                    UPPER(v_follows_group) =
                    UPPER(
                        JSON_UNQUOTE(
                            JSON_EXTRACT(
                                v_group_fields,
                                CONCAT('$[', group_number, ']')
                            )
                        )
                    )

                    AND pass_counter = 0
                )

                OR

                (
                    v_follows_group = ''
                    AND pass_counter = 1
                )

                THEN

                SET v_current_pivot_values =
                    JSON_EXTRACT
                    (
                        v_pivot_values,
                        CONCAT('$[', pivot_number, ']')
                    );

                SET v_skip_chip = FALSE;

                SET i = 0;

                validation_loop:
                WHILE i < JSON_LENGTH(v_current_pivot_values)
                DO
                    IF JSON_TYPE(
                        JSON_EXTRACT(
                            v_current_pivot_values,
                            CONCAT('$[',i,']')
                        )
                    ) = 'NULL'
                    THEN

                        SET v_skip_chip = TRUE;

                        LEAVE validation_loop;

                    END IF;

                    SET i = i + 1;

                END WHILE validation_loop;

				IF v_strict_pivot_validation
				AND v_skip_chip
				THEN

                -- -----------------------
                -- Build pivot warnings
                -- -----------------------

                    SET v_warning_messages =
                        CONCAT(
                            v_warning_messages,
                            'Easy Pivot skipped Pivot_Field "',
                            v_pivot_field,
                            '" because it contains NULL pivot values. ',
                            'Use COALESCE() or filter NULL values in the source query.',
                            CHAR(10)
                        );

                    SET pivot_number = pivot_number + 1;

                    ITERATE pivot_loop;

                END IF;

                IF v_debug_mode THEN

                    SET v_debug = CONCAT(
                        v_debug,
                        '\n\nPivot Value Arrays:\n',
                        COALESCE(JSON_PRETTY(v_pivot_values), '<SQL NULL>')
                    );

                END IF;

                SET chip_number = 0;

                WHILE chip_number < JSON_LENGTH(v_current_pivot_values)
                DO

                    SET v_pivot_value =
                        JSON_UNQUOTE(
                            JSON_EXTRACT(
                                v_current_pivot_values,
                                CONCAT('$[', chip_number, ']')
                            )
                        );

                    -- --------------------------------------------------------
                    -- CORE ENGINE
                    -- Generate SELECT list
                    -- --------------------------------------------------------

                    SET v_pivot_true =
                        JSON_UNQUOTE(
                            JSON_EXTRACT(
                                v_pivot_trues,
                                CONCAT('$[', pivot_number, ']')
                            )
                        );

                    SET v_pivot_false =
                        JSON_UNQUOTE(
                            JSON_EXTRACT(
                                v_pivot_falses,
                                CONCAT('$[', pivot_number, ']')
                            )
                        );

                    IF v_debug_mode THEN

                        SET v_debug = CONCAT(
                            v_debug,
                            '\n\n',
                            'dynamic=', COALESCE(v_dynamic_select, '<NULL>'),
                            '\npivot_type=', COALESCE(v_pivot_type, '<NULL>'),
                            '\npivot_data=', COALESCE(v_pivot_data, '<NULL>'),
                            '\npivot_value=', COALESCE(v_pivot_value, '<NULL>'),
                            '\npivot_true=', COALESCE(v_pivot_true, '<NULL>'),
                            '\npivot_false=', COALESCE(v_pivot_false, '<NULL>'),
                            '\npivot_alias=', COALESCE(CAST(v_pivot_alias AS CHAR), '<NULL>')
                        );

                    END IF;

                    IF
                        UPPER(COALESCE(v_pivot_type,'')) = 'COUNT'
                        OR
                        JSON_UNQUOTE(
                            JSON_EXTRACT(
                                v_numeric_flags,
                                CONCAT('$[',pivot_number,']')
                            )
                        ) = '1'
                    THEN

                        SET v_dynamic_select =
                            CONCAT(
                                v_dynamic_select,
                                ',\n    COALESCE(p',
                                v_pivot_alias,
                                '.`',
                                REPLACE(v_pivot_value,'`','``'),
                                '`,0) AS `',

                                CASE
                                    WHEN v_pivot_type IS NULL
                                    THEN ''
                                    ELSE CONCAT(v_pivot_type,'_')
                                END,

                                REPLACE(v_pivot_value,'`','``'),

                                '`'
                            );

                    ELSEIF v_pivot_data IS NULL THEN

                        SET v_dynamic_select =
                            CONCAT(
                                v_dynamic_select,
                                ',\n    CASE WHEN COALESCE(p',
                                v_pivot_alias,
                                '.`',
                                REPLACE(v_pivot_value,'`','``'),
                                '`,''',
                                REPLACE(v_pivot_false,'''',''''''),
                                ''') = ''',
                                REPLACE(v_pivot_false,'''',''''''),
                                ''' THEN ''',
                                REPLACE(v_pivot_false,'''',''''''),
                                ''' ELSE ''',
                                REPLACE(v_pivot_true,'''',''''''),
                                ''' END AS `',

                                CASE
                                    WHEN v_pivot_type IS NULL
                                    THEN ''
                                    ELSE CONCAT(v_pivot_type,'_')
                                END,

                                REPLACE(v_pivot_value,'`','``'),
                                '`'
                            );

ELSE

                            SET v_dynamic_select =
                                CONCAT(
                                    v_dynamic_select,
                                    ',\n    COALESCE(p',
                                    v_pivot_alias,
                                    '.`',
                                    REPLACE(v_pivot_value,'`','``'),
                                    '`,'''') AS `',

                                    CASE
                                        WHEN v_pivot_type IS NULL
                                        THEN ''
                                        ELSE CONCAT(v_pivot_type,'_')
                                    END,

                                    REPLACE(v_pivot_value,'`','``'),

                                    '`'
                                );

                        END IF;

                    SET chip_number = chip_number + 1;

                END WHILE;

                -- --------------------------------------------------------
                -- FROM generation
                -- --------------------------------------------------------

                SET v_dynamic_from =
                    CONCAT(
                        v_dynamic_from,
                        '\nLEFT JOIN',
                        '\n(',
                        '\n        SELECT'
                    );

                -- --------------------------------------------------------
                -- SELECT group fields
                -- --------------------------------------------------------

                SET join_group_number = 0;

                WHILE join_group_number < JSON_LENGTH(v_group_fields)
                DO

                    IF join_group_number > 0 THEN

                        SET v_dynamic_from =
                            CONCAT(
                                v_dynamic_from,
                                ','
                            );

                    END IF;

                    SET v_dynamic_from =
                        CONCAT(
                            v_dynamic_from,
                            '\n            `',
                            JSON_UNQUOTE(
                                JSON_EXTRACT(
                                    v_group_fields,
                                    CONCAT('$[',join_group_number,']')
                                )
                            ),
                            '`'
                        );

                    SET join_group_number =
                        join_group_number + 1;

                END WHILE;

                -- --------------------------------------------------------
                -- Aggregate generation
                -- --------------------------------------------------------

                SET v_dynamic_from =
                    CONCAT(
                        v_dynamic_from,
                        ','
                    );

                SET v_first_pivot_value = 1;

                SET v_current_pivot_values =
                    JSON_EXTRACT
                    (
                        v_pivot_values,
                        CONCAT('$[', pivot_number, ']')
                    );

                SET i = 0;

                WHILE i < JSON_LENGTH(v_current_pivot_values)
                DO

                    IF NOT v_first_pivot_value THEN

                        SET v_dynamic_from =
                            CONCAT(
                                v_dynamic_from,
                                ','
                            );

                    END IF;

                    SET v_first_pivot_value = 0;

                    SET v_dynamic_from =
                        CONCAT(
                            v_dynamic_from,
                            '\n        ',
                            v_sql_pivot_type,
                            '(CASE WHEN `',
                            v_pivot_field,
                            '` = ''',
                            REPLACE(
                                JSON_UNQUOTE(
                                    JSON_EXTRACT(
                                        v_current_pivot_values,
                                        CONCAT('$[',i,']')
                                    )
                                ),
                                '''',
                                ''''''
                            ),
                            ''' THEN `'
                        );

                        IF v_pivot_data IS NULL THEN

                            SET v_dynamic_from =
                                CONCAT(
                                    v_dynamic_from,
                                    v_pivot_field
                                );

                        ELSE

                            SET v_dynamic_from =
                                CONCAT(
                                    v_dynamic_from,
                                    v_pivot_data
                                );

                        END IF;

                        SET v_dynamic_from =
                            CONCAT(
                                v_dynamic_from,
                                '` END) AS `',
                                JSON_UNQUOTE(
                                    JSON_EXTRACT(
                                        v_current_pivot_values,
                                        CONCAT('$[',i,']')
                                    )
                                ),
                                '`'
                            );

                    SET i = i + 1;

                END WHILE;

                -- --------------------------------------------------------
                -- FROM source
                -- --------------------------------------------------------

                SET v_dynamic_from =
                    CONCAT(
                        v_dynamic_from,
                        '\n    FROM',
                        '\n    (',
                        '\n',
                        p_user_sql,
                        '\n    ) q',
                        '\n    GROUP BY'
                    );

                    -- --------------------------------------------------------
                    -- GROUP BY
                    -- --------------------------------------------------------

                    SET join_group_number = 0;

                    WHILE join_group_number < JSON_LENGTH(v_group_fields)
                    DO

                        IF join_group_number > 0 THEN

                            SET v_dynamic_from =
                                CONCAT(
                                    v_dynamic_from,
                                    ','
                                );

                        END IF;

                        SET v_dynamic_from =
                            CONCAT(
                                v_dynamic_from,
                                '\n        `',
                                JSON_UNQUOTE(
                                    JSON_EXTRACT(
                                        v_group_fields,
                                        CONCAT('$[',join_group_number,']')
                                    )
                                ),
                                '`'
                            );

                        SET join_group_number =
                            join_group_number + 1;

                    END WHILE;

                    SET v_dynamic_from =
                        CONCAT(
                            v_dynamic_from,
                            '\n) p',
                            v_pivot_alias,
                            '\n'
                        );

                    -- --------------------------------------------------------
                    -- JOIN conditions
                    -- --------------------------------------------------------

                    SET join_group_number = 0;

                    WHILE join_group_number < JSON_LENGTH(v_group_fields)
                    DO

                        SET v_dynamic_from =
                            CONCAT(
                                v_dynamic_from,

                                CASE
                                    WHEN join_group_number = 0
                                    THEN CONCAT('ON p',v_pivot_alias,'.`')
                                    ELSE CONCAT('AND p',v_pivot_alias,'.`')
                                END,

                                JSON_UNQUOTE(
                                    JSON_EXTRACT(
                                        v_group_fields,
                                        CONCAT('$[',join_group_number,']')
                                    )
                                ),

                                '` = ep.`',

                                JSON_UNQUOTE(
                                    JSON_EXTRACT(
                                        v_group_fields,
                                        CONCAT('$[',join_group_number,']')
                                    )
                                ),

                                '`\n'
                            );

                        SET join_group_number =
                            join_group_number + 1;

                    END WHILE;

                    SET v_pivot_alias =
                        v_pivot_alias + 1;

                    IF pass_counter = 1 THEN
                        SET group_number = v_group_count;
                    END IF;

                END IF;

                SET pivot_number = pivot_number + 1;

            END WHILE;

            SET group_number = group_number + 1;

        END WHILE;

        SET pass_counter = pass_counter + 1;

    END WHILE;

    -- ----------------------------------------------------------------------------
    -- Build Dynamic ORDER BY
    -- ----------------------------------------------------------------------------

    SET v_dynamic_order_by = 'ORDER BY';

    SET v_first_group = TRUE;

    SET group_number = 0;

    WHILE group_number < JSON_LENGTH(v_group_fields)
    DO

        SET v_group_field =
            JSON_UNQUOTE(
                JSON_EXTRACT(
                    v_group_fields,
                    CONCAT('$[',group_number,']')
                )
            );

        SET v_group_order =
            UPPER(
                COALESCE(
                    JSON_UNQUOTE(
                        JSON_EXTRACT(
                            v_group_orders,
                            CONCAT('$[',group_number,']')
                        )
                    ),
                    'ASC'
                )
            );

        IF NOT v_first_group THEN

            SET v_dynamic_order_by =
                CONCAT(
                    v_dynamic_order_by,
                    ',\n'
                );

        ELSE

            SET v_dynamic_order_by =
                CONCAT(
                    v_dynamic_order_by,
                    '\n'
                );

            SET v_first_group = FALSE;

        END IF;

        SET v_dynamic_order_by =
            CONCAT(
                v_dynamic_order_by,
                '    ep.`',
                v_group_field,
                '` ',
                CASE
                    WHEN v_group_order IN ('ASC','DESC')
                    THEN v_group_order
                    ELSE 'ASC'
                END
            );

        SET group_number = group_number + 1;

    END WHILE;

    -- ----------------------------------------------------------------------------
    -- Build Final SQL
    -- ----------------------------------------------------------------------------

    SET v_final_sql =
        CONCAT(
            v_dynamic_select,
            '\n',
            v_dynamic_from,
            '\n',
            v_dynamic_order_by,
            ';'
        );

    -- ----------------------------------------------------------------------------
    -- Normalize formatting
    -- ----------------------------------------------------------------------------

    SET v_final_sql =
        REPLACE(
            REPLACE(
                v_final_sql,
                '\r\n',
                '\n'
            ),
            '\r',
            '\n'
        );

    WHILE INSTR(v_final_sql,'\n\n') > 0
    DO

        SET v_final_sql =
            REPLACE(
                v_final_sql,
                '\n\n',
                '\n'
            );

    END WHILE;

    SET v_final_sql = TRIM(v_final_sql);

    -- ----------------------------------------------------------------------------
    -- Output or Execute
    -- ----------------------------------------------------------------------------

    IF p_generate_source_code_only THEN

        IF v_debug_mode THEN

            SELECT
                CONCAT(
                    '============= EASY PIVOT DEVELOPER TRACE --> MYSQL ============',
                    '\n\n',
                    v_debug,
                    '\n\n',
                    '======================== GENERATED SQL ========================',
                    '\n\n',
                    v_final_sql
                ) AS Generated_SQL;

        ELSE

            SELECT
                v_final_sql AS Generated_SQL;

        END IF;

    ELSE

        SET @sql = v_final_sql;

        PREPARE stmt FROM @sql;

        EXECUTE stmt;

        DEALLOCATE PREPARE stmt;

    END IF;

    SET p_warning_messages = v_warning_messages;

END$$

DELIMITER ;