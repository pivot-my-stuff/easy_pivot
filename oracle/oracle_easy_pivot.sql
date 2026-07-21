SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF

DECLARE

    ----------------------------------------------------------------------------
    -- USER AREA
    ----------------------------------------------------------------------------

    v_user_sql CLOB := q'[
        SELECT
            OWNER,
            OBJECT_NAME,
            OBJECT_TYPE,
            STATUS,
            LENGTH(OBJECT_NAME) AS NAME_LENGTH
        FROM
            ALL_OBJECTS
        WHERE
            ROWNUM <= 500
    ]';

     v_json_configuration CLOB := '
        [
            {
                "Group": ["OWNER", "OBJECT_NAME"],
                "Order": ["ASC", "ASC"],

                "Pivot":
                [
                    {"Pivot_Field": "OBJECT_TYPE", "Pivot_Type": "AVG", "Pivot_Data": "NAME_LENGTH", "Follows_Group": "OWNER"}
                   ,{"Pivot_Field": "STATUS", "Pivot_True": "Valid", "Pivot_False": "", "Follows_Group": "OBJECT_NAME"}
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

    TYPE pivot_true_array IS TABLE OF VARCHAR2(4000)
        INDEX BY PLS_INTEGER;
    
    TYPE pivot_false_array IS TABLE OF VARCHAR2(4000)
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
    v_pivot_trues                pivot_true_array;
    v_pivot_falses               pivot_false_array;
    v_pivot_follows              pivot_follow_array;
    v_pivot_sort_orders          pivot_sort_array;
    v_pivot_value_fields         pivot_value_field_table;
    v_numeric_flags              number_table;

    ----------------------------------------------------------------------------
    -- HELPER FUNCTIONS
    ----------------------------------------------------------------------------
    
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

    PROCEDURE print_group_fields
    IS
    BEGIN

        print_banner('GROUP FIELDS');

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
            DBMS_OUTPUT.PUT_LINE(r.group_field);
        END LOOP;

    END;

    PROCEDURE print_order_fields
    IS
    BEGIN

        print_banner('ORDER FIELDS');

        FOR r IN
        (
            SELECT
                TRIM(order_field) AS order_field
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
        )
        LOOP
            DBMS_OUTPUT.PUT_LINE(r.order_field);
        END LOOP;

    END;

    PROCEDURE print_pivot_definitions
    IS
    BEGIN

        print_banner('PIVOT DEFINITIONS');

        FOR r IN
        (
            SELECT
                pivot_position AS pivot_number,
                pivot_field,
                pivot_data,
                pivot_true,
                pivot_false,
                pivot_type,
                follows_group,
                sort_order
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
                        sort_order    VARCHAR2(4000) PATH '$.Sort_Order'
                    )
                )
            )
        )
        LOOP

            DBMS_OUTPUT.PUT_LINE('----------------------------------------');
            DBMS_OUTPUT.PUT_LINE('Pivot #' || r.pivot_number);
            DBMS_OUTPUT.PUT_LINE('Pivot_Field   : ' || NVL(r.pivot_field,'NULL'));
            DBMS_OUTPUT.PUT_LINE('Pivot_Data    : ' || NVL(r.pivot_data,'NULL'));
            DBMS_OUTPUT.PUT_LINE('Pivot_True    : ' || NVL(r.pivot_true,'NULL'));
            DBMS_OUTPUT.PUT_LINE('Pivot_False   : ' || NVL(r.pivot_false,'NULL'));
            DBMS_OUTPUT.PUT_LINE('Pivot_Type    : ' || NVL(r.pivot_type,'NULL'));
            DBMS_OUTPUT.PUT_LINE('Follows_Group : ' || NVL(r.follows_group,'NULL'));
            DBMS_OUTPUT.PUT_LINE('Sort_Order    : ' || NVL(r.sort_order,'NULL'));

        END LOOP;

        DBMS_OUTPUT.PUT_LINE('----------------------------------------');

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

        IF v_debug = 1 THEN
        
            DBMS_OUTPUT.PUT_LINE('');
            DBMS_OUTPUT.PUT_LINE('Loaded Groups:');
        
            FOR i IN 1 .. v_group_count
            LOOP
                DBMS_OUTPUT.PUT_LINE
                (
                    'Group #' || i || ' = '
                    || v_group_fields(i)
                );
            END LOOP;
        
        END IF;

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
            
            v_pivot_trues(v_pivot_count) :=
                r.pivot_true;
            
            v_pivot_falses(v_pivot_count) :=
                r.pivot_false;
            
            v_pivot_follows(v_pivot_count) :=
                r.follows_field;
            
            v_pivot_sort_orders(v_pivot_count) :=
                r.sort_order;

            IF v_debug = 1 THEN

            DBMS_OUTPUT.PUT_LINE(
                   'Loaded Pivot #'
                || v_pivot_count
                || ' type='
                || NVL(v_pivot_types(v_pivot_count),'BOOLEAN')
            );

            END IF;

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
        
            OPEN pivot_cursor FOR v_pivot_discovery_sql;
        
            LOOP
        
                FETCH pivot_cursor
                INTO v_pivot_value;
        
                EXIT WHEN pivot_cursor%NOTFOUND;
     
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
    
    PROCEDURE print_pivot_discovery
    IS
    BEGIN
    
        print_banner('PIVOT VALUE DISCOVERY');
    
        DBMS_OUTPUT.PUT_LINE('Pivot Field:');
        DBMS_OUTPUT.PUT_LINE(v_pivot_field);
    
        DBMS_OUTPUT.PUT_LINE(CHR(10));
    
        DBMS_OUTPUT.PUT_LINE('Generated Discovery SQL:');
        DBMS_OUTPUT.PUT_LINE(v_pivot_discovery_sql);
    
        DBMS_OUTPUT.PUT_LINE(CHR(10));
    
        DBMS_OUTPUT.PUT_LINE('Discovered Pivot Values:');
    
        FOR i IN 1 .. v_pivot_value_count
        LOOP
    
            DBMS_OUTPUT.PUT_LINE
            (
                'Pivot Chip #'
                || i
                || ' = '
                || v_pivot_values(i)
            );
    
        END LOOP;
    
    END;
    
    PROCEDURE print_dynamic_order_by
    IS
    BEGIN
    
        print_banner('DYNAMIC ORDER BY');
    
        IF v_dynamic_order_by IS NULL THEN
            DBMS_OUTPUT.PUT_LINE('<NULL>');
        ELSE
            DBMS_OUTPUT.PUT_LINE(v_dynamic_order_by);
        END IF;
    
    END;
    
    PROCEDURE print_final_sql
    IS
    BEGIN
    
        print_banner('FINAL SQL');
    
        IF v_final_sql IS NULL THEN
            DBMS_OUTPUT.PUT_LINE('<NULL>');
        ELSE
            DBMS_OUTPUT.PUT_LINE(v_final_sql);
        END IF;
    
    END;

    PROCEDURE build_dynamic_select_and_from
    IS
        v_pivot_alias       NUMBER := 1;
        v_first_pivot_value NUMBER := 1;
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
        -- PASS 1
        -- Process pivots attached to groups
        ---------------------------------------------------------
    
        FOR group_number IN 1 .. v_group_count
        LOOP
        
            -------------------------------------------------
            -- Emit current group field
            -------------------------------------------------
        
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
        
            -------------------------------------------------
            -- Emit pivots following this group
            -------------------------------------------------
        
            FOR pivot_number IN 1 .. v_pivot_count
            LOOP
    
                IF UPPER(TRIM(NVL(v_pivot_follows(pivot_number), '')))
                   =
                   UPPER(TRIM(v_group_fields(group_number)))
                THEN
    
                IF v_debug = 1 THEN

                    DBMS_OUTPUT.PUT_LINE(
                           'Assigning physical alias p'
                        || v_pivot_alias
                        || ' to logical pivot #'
                        || pivot_number
                    );

                    DBMS_OUTPUT.PUT_LINE(
                           'Building SELECT for pivot '
                        || pivot_number
                        || ' using alias p'
                        || v_pivot_alias
                        || ' type='
                        || NVL(v_pivot_types(pivot_number),'BOOLEAN')
                    );

                END IF;
                    
                    -------------------------------------------------
                    -- SELECT generation
                    -------------------------------------------------
    
                    FOR chip_number IN 1 .. v_pivot_value_count
                    LOOP
    
                        IF v_pivot_value_fields(chip_number)
                           =
                           v_pivot_fields(pivot_number)
                        THEN
    
                            IF v_numeric_flags(pivot_number) > 0 THEN
                            
                                v_dynamic_select :=
                                       v_dynamic_select
                                    || ','
                                    || CHR(10)
                                    || '    NVL(p'
                                    || v_pivot_alias
                                    || '."'
                                    || v_pivot_values(chip_number)
                                    || '",0) AS "'
                                    || v_pivot_types(pivot_number)
                                    || '_'
                                    || v_pivot_values(chip_number)
                                    || '"';
                            
                            ELSIF v_pivot_datas(pivot_number) IS NOT NULL THEN
                            
                                v_dynamic_select :=
                                       v_dynamic_select
                                    || ','
                                    || CHR(10)
                                    || '    p'
                                    || v_pivot_alias
                                    || '."'
                                    || v_pivot_values(chip_number)
                                    || '" AS "'
                                    || v_pivot_types(pivot_number)
                                    || '_'
                                    || v_pivot_values(chip_number)
                                    || '"';
                            
                            ELSE
                            
                                v_dynamic_select :=
                                       v_dynamic_select
                                    || ','
                                    || CHR(10)
                                    || '    NVL(p'
                                    || v_pivot_alias
                                    || '."'
                                    || v_pivot_values(chip_number)
                                    || '",NULL) AS "'
                                    || v_pivot_values(chip_number)
                                    || '"';
                            
                            END IF;
    
                        END IF;
    
                    END LOOP;

                    IF v_debug = 1 THEN

                        DBMS_OUTPUT.PUT_LINE(
                               'Building FROM for pivot '
                            || pivot_number
                            || ' using alias p'
                            || v_pivot_alias
                            || ' type='
                            || NVL(v_pivot_types(pivot_number),'BOOLEAN')
                        );

                    END IF;

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
    
                    IF v_pivot_datas(pivot_number) IS NOT NULL THEN
    
                        v_dynamic_from :=
                               v_dynamic_from
                            || ','
                            || CHR(10)
                            || '            '
                            || v_pivot_fields(pivot_number)
                            || ','
                            || CHR(10)
                            || '            '
                            || v_pivot_datas(pivot_number);
    
                    ELSE
    
                        v_dynamic_from :=
                               v_dynamic_from
                            || ','
                            || CHR(10)
                            || '            '
                            || v_pivot_fields(pivot_number);
    
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
                            WHEN v_pivot_datas(pivot_number) IS NULL
                            THEN
                                'MAX('
                                || v_pivot_fields(pivot_number)
                                || ')'
                            ELSE
                                translate_aggregate(v_pivot_types(pivot_number))
                                || '('
                                || v_pivot_datas(pivot_number)
                                || ')'
                        END
    
                        || CHR(10)
                        || '        FOR '
                        || v_pivot_fields(pivot_number)
                        || ' IN'
                        || CHR(10)
                        || '        (';
    
                    v_first_pivot_value := 1;
    
                    FOR i IN 1 .. v_pivot_value_count
                    LOOP
    
                        IF v_pivot_value_fields(i)
                           =
                           v_pivot_fields(pivot_number)
                        THEN
    
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
                                || v_pivot_values(i)
                                || ''' AS "'
                                || v_pivot_values(i)
                                || '"';
    
                        END IF;
    
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
    
        END LOOP;
    
        ---------------------------------------------------------
        -- PASS 2
        -- Process pivots without Follows_Group values
        ---------------------------------------------------------
    
        FOR pivot_number IN 1 .. v_pivot_count
        LOOP
    
            IF v_pivot_follows(pivot_number) IS NULL
               OR
               TRIM(v_pivot_follows(pivot_number)) = ''
            THEN

                IF v_debug = 1 THEN

                DBMS_OUTPUT.PUT_LINE(
                       'Assigning physical alias p'
                    || v_pivot_alias
                    || ' to logical pivot #'
                    || pivot_number
                );
    
                END IF;
                -------------------------------------------------
                -- SELECT generation
                -------------------------------------------------
    
                FOR chip_number IN 1 .. v_pivot_value_count
                LOOP
    
                    IF v_pivot_value_fields(chip_number)
                       =
                       v_pivot_fields(pivot_number)
                    THEN
    
                        IF v_numeric_flags(pivot_number) > 0 THEN
                        
                            v_dynamic_select :=
                                   v_dynamic_select
                                || ','
                                || CHR(10)
                                || '    NVL(p'
                                || v_pivot_alias
                                || '."'
                                || v_pivot_values(chip_number)
                                || '",0) AS "'
                                || v_pivot_types(pivot_number)
                                || '_'
                                || v_pivot_values(chip_number)
                                || '"';
                        
                        ELSIF v_pivot_datas(pivot_number) IS NOT NULL THEN
                        
                            v_dynamic_select :=
                                   v_dynamic_select
                                || ','
                                || CHR(10)
                                || '    p'
                                || v_pivot_alias
                                || '."'
                                || v_pivot_values(chip_number)
                                || '" AS "'
                                || v_pivot_types(pivot_number)
                                || '_'
                                || v_pivot_values(chip_number)
                                || '"';
                        
                        ELSE
                        
                            v_dynamic_select :=
                                   v_dynamic_select
                                || ','
                                || CHR(10)
                                || '    NVL(p'
                                || v_pivot_alias
                                || '."'
                                || v_pivot_values(chip_number)
                                || '",NULL) AS "'
                                || v_pivot_values(chip_number)
                                || '"';
                        
                        END IF;
    
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
    
                IF v_pivot_datas(pivot_number) IS NOT NULL THEN
    
                    v_dynamic_from :=
                           v_dynamic_from
                        || ','
                        || CHR(10)
                        || '            '
                        || v_pivot_fields(pivot_number)
                        || ','
                        || CHR(10)
                        || '            '
                        || v_pivot_datas(pivot_number);
    
                ELSE
    
                    v_dynamic_from :=
                           v_dynamic_from
                        || ','
                        || CHR(10)
                        || '            '
                        || v_pivot_fields(pivot_number);
    
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
                        WHEN v_pivot_datas(pivot_number) IS NULL
                        THEN
                            'MAX('
                            || v_pivot_fields(pivot_number)
                            || ')'
                        ELSE
                            translate_aggregate(v_pivot_types(pivot_number))
                            || '('
                            || v_pivot_datas(pivot_number)
                            || ')'
                    END
    
                    || CHR(10)
                    || '        FOR '
                    || v_pivot_fields(pivot_number)
                    || ' IN'
                    || CHR(10)
                    || '        (';
    
                v_first_pivot_value := 1;
    
                FOR i IN 1 .. v_pivot_value_count
                LOOP
    
                    IF v_pivot_value_fields(i)
                       =
                       v_pivot_fields(pivot_number)
                    THEN
    
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
                            || v_pivot_values(i)
                            || ''' AS "'
                            || v_pivot_values(i)
                            || '"';
    
                    END IF;
    
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

-- ========= DEBUGGING ==========
    IF v_debug = 1 THEN

        print_group_fields;
        print_order_fields;
        print_pivot_definitions;
        print_pivot_discovery;

    END IF;
-- ==============================

-- ========= BUILD ==============
    build_dynamic_select_and_from;
    build_dynamic_order_by;
    build_final_sql;
-- ==============================

-- ========= PRINT ==============
    IF v_debug = 1 THEN

        print_dynamic_order_by;
        print_final_sql;

    END IF;
-- ==============================

--  ========= EXECUTE ============
    execute_final_sql;
--  ==============================
    
END;
/