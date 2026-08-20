-- ============================================================
-- Example 4: String Pivot Values
-- ============================================================
--
-- Demonstrates:
--
--     * String pivots
--     * Pivot_True
--     * Pivot_False
--     * Oracle VARCHAR handling
--
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF

DECLARE

    ----------------------------------------------------------------------------
    -- USER AREA
    ----------------------------------------------------------------------------

    v_user_sql CLOB := q'[
        SELECT
            OWNER,
            STATUS
        FROM
            ALL_OBJECTS
    ]';

     v_json_configuration CLOB := '
        [
            {
                "Group": ["OWNER"],
                "Order": ["ASC"],
                "Pivot":
                [
                    {"Pivot_Field": "STATUS", "Pivot_True": "Present", "Pivot_False": ""}
                ]
            }
        ]
    ';

    -- Change to 1 to print generated pivot code
    v_generate_source_code_only  NUMBER(1) := 1;

    -- Change to 1 to enable debugging output
    v_debug                      NUMBER(1) := 0;
    
    ----------------------------------------------------------------------------
    -- EASY PIVOT ENGINE
    ----------------------------------------------------------------------------

    TYPE pivot_cursor_type IS REF CURSOR;
    pivot_cursor pivot_cursor_type;
    
    TYPE pivot_value_array_type IS TABLE OF VARCHAR2(4000)
    INDEX BY PLS_INTEGER;

    TYPE pivot_type_array IS TABLE OF VARCHAR2(4000)
        INDEX BY PLS_INTEGER;
    
    TYPE pivot_data_array IS TABLE OF VARCHAR2(4000)
        INDEX BY PLS_INTEGER;
    
    TYPE pivot_field_array IS TABLE OF VARCHAR2(4000)
        INDEX BY PLS_INTEGER;

    TYPE pivot_follow_array IS TABLE OF VARCHAR2(4000)
        INDEX BY PLS_INTEGER;
    
    TYPE pivot_sort_array IS TABLE OF VARCHAR2(4000)
        INDEX BY PLS_INTEGER;

    TYPE group_field_array IS TABLE OF VARCHAR2(4000)
        INDEX BY PLS_INTEGER;
        
    TYPE pivot_value_field_table IS TABLE OF VARCHAR2(4000)
        INDEX BY PLS_INTEGER;

    TYPE number_table IS TABLE OF NUMBER INDEX BY PLS_INTEGER;

    TYPE pivot_true_array IS TABLE OF VARCHAR2(4000)
        INDEX BY PLS_INTEGER;
    
    TYPE pivot_false_array IS TABLE OF VARCHAR2(4000)
        INDEX BY PLS_INTEGER;

    v_pivot_field                VARCHAR2(4000);
    v_pivot_discovery_sql        CLOB;
    v_pivot_value                VARCHAR2(4000);
    v_dynamic_select             CLOB;
    v_dynamic_from               CLOB;
    v_dynamic_order_by           CLOB;
    v_final_sql                  CLOB;
    v_pivot_value_count          NUMBER := 0;
    v_pivot_values               pivot_value_array_type;
    v_pivot_types                pivot_type_array;
    v_pivot_fields               pivot_field_array;
    v_pivot_datas                pivot_data_array;
    v_pivot_count                NUMBER := 0;
    v_group_fields               group_field_array;
    v_group_count                NUMBER := 0;
    v_pivot_data                 VARCHAR2(4000);
    v_pivot_type                 VARCHAR2(4000);
    v_pivot_follows              pivot_follow_array;
    v_pivot_sort_orders          pivot_sort_array;
    v_pivot_value_fields         pivot_value_field_table;
    v_numeric_flags              number_table;
    v_pivot_trues                pivot_true_array;
    v_pivot_falses               pivot_false_array;

    ----------------------------------------------------------------------------
    -- Build procedure working variables (added during Oracle refactoring)
    ----------------------------------------------------------------------------
    
    v_numeric_flag               NUMBER := 0;
    v_discovery_sql              CLOB;
    v_current_pivot_value        VARCHAR2(4000);
    TYPE discovery_cursor_type   IS REF CURSOR;
    discovery_cursor             discovery_cursor_type;

    FUNCTION translate_aggregate
    (
        p_aggregate VARCHAR2
    )
    RETURN VARCHAR2
    IS
    BEGIN
    
        CASE UPPER(TRIM(p_aggregate))
    
            WHEN 'STDEV' THEN
                RETURN 'STDDEV';
    
            ELSE
                RETURN UPPER(TRIM(p_aggregate));
    
        END CASE;
    
    END;

    FUNCTION is_numeric_column(
        p_source_sql  IN CLOB,
        p_column_name IN VARCHAR2
    )
    RETURN NUMBER
    IS
        l_cursor        INTEGER;
        l_column_count  INTEGER;
        l_desc_tab      DBMS_SQL.DESC_TAB2;
        l_numeric_flag  NUMBER := 0;
    BEGIN

        /*
            Open parse cursor.
        */
    
        l_cursor := DBMS_SQL.OPEN_CURSOR;

        /*
            Parse source query without executing it.
        */
    
        DBMS_SQL.PARSE(
            c            => l_cursor,
            statement    => p_source_sql,
            language_flag => DBMS_SQL.NATIVE
        );

        /*
            Retrieve result set metadata.
        */
    
        DBMS_SQL.DESCRIBE_COLUMNS2(
            c           => l_cursor,
            col_cnt     => l_column_count,
            desc_t      => l_desc_tab
        );

        /*
            Locate Pivot_Data column.
        */
    
        FOR i IN 1 .. l_column_count
        LOOP
            IF LOWER(l_desc_tab(i).col_name) =
               LOWER(p_column_name)
            THEN
    
                /*
                    Oracle numeric datatypes.
    
                    NUMBER         = 2
                    BINARY_FLOAT   = 100
                    BINARY_DOUBLE  = 101
                */
    
                IF l_desc_tab(i).col_type IN (2,100,101)
                THEN
                    l_numeric_flag := 1;
                ELSE
                    l_numeric_flag := 0;
                END IF;
    
                EXIT;
            END IF;
        END LOOP;
    
        /*
            Cleanup.
        */
    
        DBMS_SQL.CLOSE_CURSOR(l_cursor);

        RETURN l_numeric_flag;
    
        EXCEPTION
            WHEN OTHERS THEN

                IF DBMS_SQL.IS_OPEN(l_cursor)
                THEN
                    DBMS_SQL.CLOSE_CURSOR(l_cursor);
                END IF;
        
                RETURN 0;

    END is_numeric_column;

    ----------------------------------------------------------------------------
    -- HELPER PROCEDURES
    ----------------------------------------------------------------------------

    PROCEDURE print_banner
    (
        p_title VARCHAR2
    )
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(CHR(10));
        DBMS_OUTPUT.PUT_LINE('-- ======================================');
        DBMS_OUTPUT.PUT('-- ');
        DBMS_OUTPUT.PUT_LINE(p_title);
        DBMS_OUTPUT.PUT_LINE('-- ======================================');
    END;

    PROCEDURE load_pivot_metadata
    IS
        v_duplicate_found BOOLEAN := FALSE;

    BEGIN
    
        v_group_count := 0;

        FOR r IN
        (
            SELECT
                TRIM(group_field) AS group_field
            FROM JSON_TABLE
            (
                v_json_configuration,
                '$[*]'
                COLUMNS
                (
                    NESTED PATH '$.Group[*]'
                    COLUMNS
                    (
                        group_field VARCHAR2(4000) PATH '$'
                    )
                )
            )
        )
        LOOP
        
            v_group_count := v_group_count + 1;
        
            v_group_fields(v_group_count) :=
                r.group_field;
        
        END LOOP;

        v_pivot_count := 0;
        
        FOR r IN
        (
            SELECT
                pivot_position,
            
                TRIM(pivot_field) AS pivot_field,
                NULLIF(TRIM(pivot_data), '') AS pivot_data,
                NVL(NULLIF(TRIM(pivot_true), ''), '') AS pivot_true,
                NVL(NULLIF(TRIM(pivot_false), ''), '') AS pivot_false,
                TRIM(pivot_type) AS pivot_type,
                COALESCE
                (
                    NULLIF(TRIM(follows_group), ''),
                    NULLIF(TRIM(follows_field), '')
                ) AS follows_field,
                NVL(NULLIF(TRIM(sort_order), ''), 'ASC') AS sort_order
            FROM JSON_TABLE
            (
                v_json_configuration,
                '$[*]'
                COLUMNS
                (
                    NESTED PATH '$.Pivot[*]'
                    COLUMNS
                    (
                        pivot_position FOR ORDINALITY,
                    
                        pivot_field   VARCHAR2(4000) PATH '$.Pivot_Field',
                        pivot_data    VARCHAR2(4000) PATH '$.Pivot_Data',
                        pivot_true    VARCHAR2(4000) PATH '$.Pivot_True',
                        pivot_false   VARCHAR2(4000) PATH '$.Pivot_False',
                        pivot_type    VARCHAR2(4000) PATH '$.Pivot_Type',
                        follows_group VARCHAR2(4000) PATH '$.Follows_Group',
                        follows_field VARCHAR2(4000) PATH '$.Follows_Field',
                        sort_order    VARCHAR2(4000) PATH '$.Sort_Order'
                    )
                )
            )
            ORDER BY
                pivot_position
        )
        LOOP                
            v_pivot_count := v_pivot_count + 1;
        
            v_pivot_fields(v_pivot_count) :=
                r.pivot_field;
        
            v_pivot_datas(v_pivot_count) :=
                r.pivot_data;
        
            v_pivot_types(v_pivot_count) :=
                r.pivot_type;

            /*
                Oracle treats empty strings as NULL.
            
                Preserve user intent by storing a single space whenever
                Pivot_True or Pivot_False is blank. The generated SQL
                will emit a visually blank value instead of Oracle NULL.
            */

            IF r.pivot_true IS NULL THEN
            
                v_pivot_trues(v_pivot_count) := ' ';
            
            ELSE
            
                v_pivot_trues(v_pivot_count) := r.pivot_true;
            
            END IF;
            
            IF r.pivot_false IS NULL THEN
            
                v_pivot_falses(v_pivot_count) := ' ';
            
            ELSE
            
                v_pivot_falses(v_pivot_count) := r.pivot_false;
            
            END IF;

            v_pivot_follows(v_pivot_count) :=
                r.follows_field;
            
            v_pivot_sort_orders(v_pivot_count) :=
                r.sort_order;

        END LOOP;

        IF v_pivot_count > 0 THEN
        
            FOR pivot_number IN 1 .. v_pivot_count
            LOOP
            
                v_pivot_field :=
                    v_pivot_fields(pivot_number);
                
                v_pivot_data :=
                    v_pivot_datas(pivot_number);
                
                v_pivot_type :=
                    v_pivot_types(pivot_number);
                    
                v_numeric_flags(pivot_number) := 0;
                
                IF v_pivot_data IS NOT NULL THEN
                
                    v_numeric_flags(pivot_number) :=
                        is_numeric_column
                        (
                            v_user_sql,
                            v_pivot_data
                        );
                
                END IF;
        
            v_pivot_discovery_sql :=
                   'SELECT DISTINCT '
                || v_pivot_field
                || CHR(10)
                || 'FROM'
                || CHR(10)
                || '('
                || CHR(10)
                || v_user_sql
                || CHR(10)
                || ') ep_source'
                || CHR(10)
                || 'ORDER BY '
                || v_pivot_field
                || ' '
                || CASE
                        WHEN UPPER(v_pivot_sort_orders(pivot_number))
                             IN ('ASC','DESC')
                        THEN
                             UPPER(v_pivot_sort_orders(pivot_number))
                       ELSE 'ASC'
                   END;
 
                IF v_debug = 1 THEN

                    print_banner('Metadata Discovery');

                    DBMS_OUTPUT.PUT_LINE(
                        'Pivot Field: ' ||
                        NVL(v_pivot_field,'<NULL>')
                    );

                    DBMS_OUTPUT.PUT_LINE(CHR(10));
                    DBMS_OUTPUT.PUT_LINE(v_pivot_discovery_sql);

                END IF;

                OPEN pivot_cursor FOR v_pivot_discovery_sql;
            
                LOOP
                
                    FETCH pivot_cursor
                    INTO v_pivot_value;

                    EXIT WHEN pivot_cursor%NOTFOUND;

                    IF v_debug = 1 THEN
                        DBMS_OUTPUT.PUT_LINE(
                            'Metadata Value: ' ||
                            NVL(v_pivot_value,'<NULL>')
                        );
                    END IF;

                     v_duplicate_found := FALSE;
                    
                    FOR existing_chip IN 1 .. v_pivot_value_count
                    LOOP
                    
                        IF v_pivot_values(existing_chip) =
                           v_pivot_value
                           AND
                           v_pivot_value_fields(existing_chip) =
                           v_pivot_field
                        THEN
                            v_duplicate_found := TRUE;
                            EXIT;
                        END IF;
                    
                    END LOOP;
                    
                    IF NOT v_duplicate_found THEN
            
                    v_pivot_value_count :=
                        v_pivot_value_count + 1;
                    
                    v_pivot_values(v_pivot_value_count) :=
                        v_pivot_value;
                    
                    v_pivot_value_fields(v_pivot_value_count) :=
                        v_pivot_field;
        
                    END IF;
                    
                END LOOP;
            
                CLOSE pivot_cursor;
    
            END LOOP;

        END IF;

    END;

    PROCEDURE build_dynamic_select_and_from
    IS
        v_pivot_alias       NUMBER := 1;
        v_first_pivot_value NUMBER := 1;
        v_pass_counter      NUMBER;
        v_numeric_flag        NUMBER := 0;
        v_discovery_sql       CLOB;
        v_current_pivot_value VARCHAR2(4000);
        TYPE discovery_cursor_type IS REF CURSOR;
        discovery_cursor discovery_cursor_type;

        TYPE local_pivot_value_array IS TABLE OF VARCHAR2(4000)
            INDEX BY PLS_INTEGER;

        v_local_pivot_values local_pivot_value_array;
        v_local_pivot_count  NUMBER := 0;

    BEGIN

        ---------------------------------------------------------
        -- SELECT HEADER
        ---------------------------------------------------------

        v_dynamic_select := 'SELECT';

        ---------------------------------------------------------
        -- FROM HEADER
        ---------------------------------------------------------

        v_dynamic_from :=
            'FROM'
            || CHR(10)
            || '('
            || CHR(10)
            || '    SELECT DISTINCT';

        FOR group_number IN 1 .. v_group_count
        LOOP

            IF group_number > 1 THEN

                v_dynamic_from :=
                    v_dynamic_from
                    || ',';

            END IF;

            v_dynamic_from :=
                v_dynamic_from
                || CHR(10)
                || '        '
                || v_group_fields(group_number);

        END LOOP;

        v_dynamic_from :=
               v_dynamic_from
            || CHR(10)
            || '    FROM'
            || CHR(10)
            || '    ('
            || v_user_sql
            || ') ep_source'
            || CHR(10)
            || ') ep'
            || CHR(10);

        ---------------------------------------------------------
        -- Easy Pivot two-pass algorithm
        ---------------------------------------------------------

        FOR v_pass_counter IN 1 .. 2
        LOOP

            FOR group_number IN 1 .. v_group_count
            LOOP

                -------------------------------------------------
                -- Emit current group field (pass 1 only)
                -------------------------------------------------

                IF v_pass_counter = 1 THEN

                    IF v_dynamic_select <> 'SELECT' THEN

                        v_dynamic_select :=
                            v_dynamic_select
                            || ',';

                    END IF;

                    v_dynamic_select :=
                        v_dynamic_select
                        || CHR(10)
                        || '    ep.'
                        || v_group_fields(group_number);

                END IF;

                -------------------------------------------------
                -- Process pivots
                -------------------------------------------------

                FOR pivot_number IN 1 .. v_pivot_count
                LOOP

                    IF
                    (
                        v_pass_counter = 1

                        AND

                        UPPER(TRIM(NVL(v_pivot_follows(pivot_number), '')))
                        =
                        UPPER(TRIM(v_group_fields(group_number)))
                    )

                    OR

                    (
                        v_pass_counter = 2

                        AND

                        (
                            v_pivot_follows(pivot_number) IS NULL

                            OR

                            TRIM(v_pivot_follows(pivot_number)) = ''
                        )
                    )

                    THEN

                        -------------------------------------------------
                        -- Load current pivot metadata
                        -------------------------------------------------

                        v_pivot_field :=
                            v_pivot_fields(pivot_number);

                        v_pivot_type :=
                            v_pivot_types(pivot_number);

                        v_pivot_data :=
                            v_pivot_datas(pivot_number);

                        -------------------------------------------------
                        -- Determine whether THIS pivot's data is numeric
                        -------------------------------------------------
                        
                        v_numeric_flag := v_numeric_flags(pivot_number);
                        
                        IF v_debug = 1 THEN
                            DBMS_OUTPUT.PUT_LINE(
                                'Numeric Flag: ' || v_numeric_flag
                            );
                        END IF;

                        -------------------------------------------------
                        -- Discover THIS pivot's values
                        -------------------------------------------------

                        v_local_pivot_values.DELETE;
                        v_local_pivot_count := 0;

                        v_discovery_sql :=
                               'SELECT DISTINCT '
                            || v_pivot_field
                            || CHR(10)
                            || 'FROM'
                            || CHR(10)
                            || '('
                            || CHR(10)
                            || v_user_sql
                            || CHR(10)
                            || ')'
                            || CHR(10)
                            || 'ORDER BY 1';

                        IF v_debug = 1 THEN

                            print_banner('Pivot Discovery');

                            DBMS_OUTPUT.PUT_LINE(
                                'Pivot Field : ' ||
                                NVL(v_pivot_field,'<NULL>')
                            );

                            DBMS_OUTPUT.PUT_LINE(
                                'Pivot Type  : ' ||
                                NVL(v_pivot_type,'<NULL>')
                            );

                            DBMS_OUTPUT.PUT_LINE(
                                'Pivot Data  : ' ||
                                NVL(v_pivot_data,'<NULL>')
                            );

                            DBMS_OUTPUT.PUT_LINE(CHR(10));
                            DBMS_OUTPUT.PUT_LINE(v_discovery_sql);

                        END IF;

                        OPEN discovery_cursor FOR
                            v_discovery_sql;
                        
                        LOOP
                        
                            FETCH discovery_cursor
                            INTO v_current_pivot_value;
                            
                            EXIT WHEN discovery_cursor%NOTFOUND;
                            
                            IF v_debug = 1 THEN
                                DBMS_OUTPUT.PUT_LINE(
                                    'Pivot Value: ' ||
                                    NVL(v_current_pivot_value,'<NULL>')
                                );
                            END IF;
                            
                            IF v_current_pivot_value IS NULL THEN
                            
                                IF v_debug = 1 THEN
                                    DBMS_OUTPUT.PUT_LINE(
                                        'Skipping NULL pivot value.'
                                    );
                                END IF;
                            
                                CONTINUE;
                            
                            END IF;
                            
                            v_local_pivot_count :=
                                v_local_pivot_count + 1;
                            
                            v_local_pivot_values(v_local_pivot_count) :=
                                v_current_pivot_value;
                        
                        END LOOP;

                        CLOSE discovery_cursor;

                        -------------------------------------------------
                        -- SELECT generation
                        -------------------------------------------------

                        FOR chip_number IN 1 .. v_local_pivot_count
                        LOOP

                            IF upper(nvl(v_pivot_type, '')) = 'COUNT'
                            OR v_numeric_flag > 0
                            THEN

                                v_dynamic_select :=
                                    v_dynamic_select
                                    || ','
                                    || CHR(10)
                                    || '    NVL('
                                    || 'p'
                                    || v_pivot_alias
                                    || '."'
                                    || v_local_pivot_values(chip_number)
                                    || '",0) AS "'
                                    || CASE
                                           WHEN v_pivot_type IS NULL
                                           THEN ''
                                           ELSE v_pivot_type || '_'
                                       END
                                    || v_local_pivot_values(chip_number)
                                    || '"';

                            ELSIF v_pivot_data IS NULL THEN
                            
                                v_dynamic_select :=
                                       v_dynamic_select
                                    || ','
                                    || CHR(10)
                                    || '    CASE'
                                    || CHR(10)
                                    || '        WHEN '
                                    || 'p'
                                    || v_pivot_alias
                                    || '."'
                                    || v_local_pivot_values(chip_number)
                                    || '"'
                                    || ' IS NULL'
                                    || CHR(10)
                                    || '        THEN '''
                                    || v_pivot_falses(pivot_number)
                                    || ''''
                                    || CHR(10)
                                    || '        ELSE '''
                                    || v_pivot_trues(pivot_number)
                                    || ''''
                                    || CHR(10)
                                    || '    END AS "'
                                    || v_local_pivot_values(chip_number)
                                    || '"';

                            ELSE

                                v_dynamic_select :=
                                    v_dynamic_select
                                    || ','
                                    || CHR(10)
                                    || '    NVL('
                                    || 'p'
                                    || v_pivot_alias
                                    || '."'
                                    || v_local_pivot_values(chip_number)
                                    || '",'''') AS "'
                                    || CASE
                                           WHEN v_pivot_type IS NULL
                                           THEN ''
                                           ELSE v_pivot_type || '_'
                                       END
                                    || v_local_pivot_values(chip_number)
                                    || '"';

                            END IF;

                        END LOOP;

                       -------------------------------------------------
                        -- FROM generation
                       -------------------------------------------------

                        v_dynamic_from :=
                            v_dynamic_from
                            || 'LEFT JOIN'
                            || CHR(10)
                            || '('
                            || CHR(10)
                            || '    SELECT *'
                            || CHR(10)
                            || '    FROM'
                            || CHR(10)
                            || '    ('
                            || CHR(10)
                            || '        SELECT';

                        FOR join_group_number IN 1 .. v_group_count
                        LOOP

                            IF join_group_number > 1 THEN

                                v_dynamic_from :=
                                    v_dynamic_from
                                    || ',';

                            END IF;

                            v_dynamic_from :=
                                v_dynamic_from
                                || CHR(10)
                                || '            '
                                || v_group_fields(join_group_number);

                        END LOOP;

                        IF v_pivot_data IS NOT NULL THEN

                            v_dynamic_from :=
                                v_dynamic_from
                                || ','
                                || CHR(10)
                                || '            '
                                || v_pivot_field
                                || ','
                                || CHR(10)
                                || '            '
                                || v_pivot_data;

                        ELSE

                            v_dynamic_from :=
                                v_dynamic_from
                                || ','
                                || CHR(10)
                                || '            '
                                || v_pivot_field;

                        END IF;

                        v_dynamic_from :=
                            v_dynamic_from
                            || CHR(10)
                            || '        FROM'
                            || CHR(10)
                            || '        ('
                            || v_user_sql
                            || '    )'
                            || CHR(10)
                            || '    )'
                            || CHR(10)
                            || '    PIVOT'
                            || CHR(10)
                            || '    ('
                            || CHR(10)
                            || '        ';

                        v_dynamic_from :=
                            v_dynamic_from
                        
                            || CASE
                        
                                WHEN v_pivot_data IS NULL
                                     AND UPPER(v_pivot_type) = 'COUNT'
                                THEN
                                    'COUNT('
                                    || v_pivot_field
                                    || ')'
                        
                                WHEN v_pivot_data IS NULL
                                THEN
                                    'MAX('
                                    || v_pivot_field
                                    || ')'
                        
                                ELSE
                                    translate_aggregate(v_pivot_type)
                                    || '('
                                    || v_pivot_data
                                    || ')'
                        
                            END
                            || CHR(10)
                            || '        FOR '
                            || v_pivot_field
                            || ' IN'
                            || CHR(10)
                            || '        (';

                        v_first_pivot_value := 1;
                        
                        FOR i IN 1 .. v_local_pivot_count
                        LOOP

                            IF v_first_pivot_value = 0 THEN

                                v_dynamic_from :=
                                    v_dynamic_from
                                    || ',';

                            END IF;

                            v_first_pivot_value := 0;

                            v_dynamic_from :=
                                v_dynamic_from
                                || CHR(10)
                                || '            '''
                                || v_local_pivot_values(i)
                                || ''' AS "'
                                || v_local_pivot_values(i)
                                || '"';

                        END LOOP;

                        v_dynamic_from :=
                            v_dynamic_from
                            || CHR(10)
                            || '        )'
                            || CHR(10)
                            || '    )'
                            || CHR(10)
                            || ') p'
                            || v_pivot_alias
                            || CHR(10);

                        FOR join_group_number IN 1 .. v_group_count
                        LOOP

                            IF join_group_number = 1 THEN

                                v_dynamic_from :=
                                    v_dynamic_from
                                    || 'ON p'
                                    || v_pivot_alias
                                    || '.'
                                    || v_group_fields(join_group_number)
                                    || ' = ep.'
                                    || v_group_fields(join_group_number)
                                    || CHR(10);

                            ELSE

                                v_dynamic_from :=
                                    v_dynamic_from
                                    || 'AND p'
                                    || v_pivot_alias
                                    || '.'
                                    || v_group_fields(join_group_number)
                                    || ' = ep.'
                                    || v_group_fields(join_group_number)
                                    || CHR(10);

                            END IF;

                        END LOOP;

                        v_pivot_alias :=
                            v_pivot_alias + 1;

                    END IF;

                END LOOP;

                IF v_pass_counter = 2 THEN
                    EXIT;
                END IF;

            END LOOP;

        END LOOP;

    END;

    PROCEDURE build_dynamic_order_by
    IS
        v_first_group NUMBER(1) := 1;
    BEGIN
    
        v_dynamic_order_by :=
               'ORDER BY'
            || CHR(10);
    
        FOR r IN
        (
            SELECT
                group_field,
                order_field
            FROM
            (
                SELECT
                    ROW_NUMBER() OVER (ORDER BY ROWNUM) AS rn,
                    group_field
                FROM JSON_TABLE
                (
                    v_json_configuration,
                    '$[*]'
                    COLUMNS
                    (
                        NESTED PATH '$.Group[*]'
                        COLUMNS
                        (
                            group_field VARCHAR2(4000) PATH '$'
                        )
                    )
                )
            ) g
            JOIN
            (
                SELECT
                    ROW_NUMBER() OVER (ORDER BY ROWNUM) AS rn,
                    order_field
                FROM JSON_TABLE
                (
                    v_json_configuration,
                    '$[*]'
                    COLUMNS
                    (
                        NESTED PATH '$.Order[*]'
                        COLUMNS
                        (
                            order_field VARCHAR2(4000) PATH '$'
                        )
                    )
                )
            ) o
            ON g.rn = o.rn
        )
        LOOP
    
            IF v_first_group = 0 THEN
                v_dynamic_order_by :=
                       v_dynamic_order_by
                    || ','
                    || CHR(10);
            END IF;
    
            v_first_group := 0;
    
            v_dynamic_order_by :=
                   v_dynamic_order_by
                || '    ep.'
                || r.group_field
                || ' '
                || NVL(r.order_field,'ASC');
    
        END LOOP;
    
    END;

    PROCEDURE build_final_sql
    IS
    BEGIN
    
        v_final_sql :=
               v_dynamic_select
            || CHR(10)
            || v_dynamic_from
            || CHR(10)
            || v_dynamic_order_by;
    
    END;
    
    PROCEDURE execute_final_sql
    IS
    BEGIN
    
        IF v_generate_source_code_only = 1 THEN
    
            print_banner('EASY PIVOT: Auto-generated pivot query');
    
            DBMS_OUTPUT.PUT_LINE(
                '-- https://github.com/pivot-my-stuff/easy_pivot'
            );
    
            DBMS_OUTPUT.PUT_LINE(CHR(10));
    
            DBMS_OUTPUT.PUT_LINE(v_final_sql);
    
        ELSE

            OPEN pivot_cursor FOR v_final_sql;
            
            DBMS_SQL.RETURN_RESULT(pivot_cursor);
        
        END IF;
    END;

    BEGIN

    -- ========= DISCOVERY ==========
    load_pivot_metadata;
    -- ==============================
    
    -- ========= BUILD ==============
    build_dynamic_select_and_from;
    build_dynamic_order_by;
    build_final_sql;
    -- ==============================

    --  ========= EXECUTE ===========
    execute_final_sql;
    --  =============================
    
    END;
    /
