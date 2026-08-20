----------------------------------------------------------------------------
-- Example: String Pivot
----------------------------------------------------------------------------
--
-- Demonstrates Easy Pivot's Boolean pivot capability using
-- character data.
--
-- This example displays Yes or No depending upon whether a table
-- owner has objects within each PostgreSQL schema.
--
-- Group:
--
--     tableowner
--
-- Pivot:
--
--     schemaname
--
-- Demonstrates:
--
--     Boolean pivot
--     Pivot_True
--     Pivot_False
--     Character data
--
-- Instructions:
--
-- 1. Paste the Easy Pivot engine immediately below this USER AREA.
-- 2. Press F5 to execute the script.
-- 3. Copy the generated SQL into a new query window.
-- 4. Execute the generated SQL to view the results.
----------------------------------------------------------------------------
DO
$$

DECLARE

----------------------------------------------------------------------------
-- USER AREA
----------------------------------------------------------------------------

v_user_sql TEXT := $SQL$

SELECT
    schemaname,
    tablename,
    tableowner,
    tablespace,
    CASE
        WHEN hasindexes THEN 'Y'
        ELSE 'N'
    END AS hasindexes,
    hasrules
FROM
    pg_tables

$SQL$;


v_json_configuration JSONB := $JSON$

[
  {
    "Group": ["tableowner"],
	
    "Order": ["ASC"],
	
    "Pivot": [
	     {"Pivot_Field": "schemaname", "Pivot_Type": "Max", "Pivot_True": "Yes", "Pivot_False": "No"}
	]
  }
]

$JSON$::jsonb;


-- TRUE  = Generate SQL only
-- FALSE = Execute generated SQL
v_generate_source_code_only BOOLEAN := TRUE;


-- TRUE = Display debugging information
-- FALSE = Normal operation
v_debug BOOLEAN := FALSE;


----------------------------------------------------------------------------
-- EASY PIVOT ENGINE
----------------------------------------------------------------------------

v_pivot_discovery_sql      TEXT;
v_dynamic_select           TEXT := '';
v_dynamic_from             TEXT := '';
v_dynamic_order_by         TEXT := '';
v_final_sql                TEXT;

v_pivot_field              TEXT;
v_pivot_type               TEXT;
v_pivot_data               TEXT;
v_pivot_value              TEXT;

v_pivot_count              INTEGER := 0;
v_group_count              INTEGER := 0;
v_pivot_value_count        INTEGER := 0;

v_group_fields             TEXT[] := ARRAY[]::TEXT[];
v_group_orders             TEXT[] := ARRAY[]::TEXT[];

v_pivot_fields             TEXT[] := ARRAY[]::TEXT[];
v_pivot_types              TEXT[] := ARRAY[]::TEXT[];
v_pivot_datas              TEXT[] := ARRAY[]::TEXT[];

v_pivot_trues              TEXT[] := ARRAY[]::TEXT[];
v_pivot_falses             TEXT[] := ARRAY[]::TEXT[];

v_pivot_follows            TEXT[] := ARRAY[]::TEXT[];
v_pivot_sort_orders        TEXT[] := ARRAY[]::TEXT[];

v_pivot_values             TEXT[] := ARRAY[]::TEXT[];
v_pivot_value_numbers      INTEGER[] := ARRAY[]::INTEGER[];

v_numeric_flags            INTEGER[] := ARRAY[]::INTEGER[];

v_json_group               JSONB;
v_json_pivot               JSONB;
v_json_item                JSONB;

v_sql                      TEXT;
v_column_name              TEXT;
v_value                    TEXT;

i                          INTEGER;
j                          INTEGER;
k                          INTEGER;

record_count               INTEGER;
r                          RECORD;

v_numeric_detection_sql   TEXT;
v_detected_type           TEXT;

pivot_number              INTEGER;
group_number              INTEGER;
join_group_number         INTEGER;
chip_number               INTEGER;
existing_chip             INTEGER;

v_duplicate_found         BOOLEAN;
v_first_group             BOOLEAN;
v_first_pivot_value       INTEGER;
v_pivot_alias             INTEGER;
v_sql_pivot_type          TEXT;

c                         REFCURSOR;

v_output                  TEXT;
v_strict_pivot_validation BOOLEAN := FALSE;

BEGIN

    ----------------------------------------------------------------------------
    -- Initialize Engine
    ----------------------------------------------------------------------------

    v_dynamic_select   := '';
    v_dynamic_from     := '';
    v_dynamic_order_by := '';
    v_final_sql        := '';

    v_group_fields       := ARRAY[]::TEXT[];
    v_group_orders       := ARRAY[]::TEXT[];

    v_pivot_fields       := ARRAY[]::TEXT[];
	v_pivot_value_numbers := ARRAY[]::INTEGER[];
    v_pivot_types        := ARRAY[]::TEXT[];
    v_pivot_datas        := ARRAY[]::TEXT[];
    v_pivot_trues        := ARRAY[]::TEXT[];
    v_pivot_falses       := ARRAY[]::TEXT[];
    v_pivot_follows      := ARRAY[]::TEXT[];
    v_pivot_sort_orders  := ARRAY[]::TEXT[];

    v_pivot_values       := ARRAY[]::TEXT[];

    v_numeric_flags      := ARRAY[]::INTEGER[];

    v_group_count        := 0;
    v_pivot_count        := 0;
    v_pivot_value_count  := 0;


    ----------------------------------------------------------------------------
    -- Parse JSON Configuration
    ----------------------------------------------------------------------------

    FOR v_json_group IN
    (
        SELECT value
        FROM jsonb_array_elements(v_json_configuration)
    )
    LOOP

        ------------------------------------------------------------------------
        -- Group Fields
        ------------------------------------------------------------------------

		FOR v_json_item IN
		(
		    SELECT value
		    FROM jsonb_array_elements(v_json_group->'Group')
		)
		LOOP
		
		    v_group_fields :=
		        array_append
		        (
		            v_group_fields,
		            trim(trim(both '"' from v_json_item::text))
		        );
		
		    v_group_count := v_group_count + 1;
		
		END LOOP;


        ------------------------------------------------------------------------
        -- Group Ordering
        ------------------------------------------------------------------------

        IF v_json_group ? 'Order'
        THEN

            FOR v_value IN
            (
                SELECT jsonb_array_elements_text(v_json_group->'Order')
            )
            LOOP

                v_group_orders :=
                    array_append(
                        v_group_orders,
                        upper(trim(v_value))
                    );

            END LOOP;

        END IF;

		BEGIN
		    EXECUTE 'DROP VIEW ep_describe';
		EXCEPTION
		    WHEN undefined_table THEN
		        NULL;
		END;

        v_sql :=
            'CREATE TEMP VIEW ep_describe AS ' ||
		    'SELECT * FROM (' ||
		    v_user_sql ||
		    ') q LIMIT 0';
		
		EXECUTE v_sql;

        ------------------------------------------------------------------------
        -- Pivot Definitions
        ------------------------------------------------------------------------

        FOR v_json_pivot IN
        (
            SELECT value
            FROM jsonb_array_elements(v_json_group->'Pivot')
        )
        LOOP

            v_pivot_fields :=
                array_append(
                    v_pivot_fields,
                    trim(v_json_pivot->>'Pivot_Field')
                );

            v_pivot_types :=
                array_append(
                    v_pivot_types,
                    trim(v_json_pivot->>'Pivot_Type')
                );

            v_pivot_datas :=
                array_append(
                    v_pivot_datas,
                    NULLIF(trim(v_json_pivot->>'Pivot_Data'), '')
                );

            v_pivot_trues :=
                array_append(
                    v_pivot_trues,
                    coalesce(v_json_pivot->>'Pivot_True','')
                );

            v_pivot_falses :=
                array_append(
                    v_pivot_falses,
                    coalesce(v_json_pivot->>'Pivot_False','')
                );

            v_pivot_follows :=
                array_append(
                    v_pivot_follows,
                    trim(
                        coalesce(
                            v_json_pivot->>'Follows_Group',
                            v_json_pivot->>'Follows_Field',
                            ''
                        )
                    )
                );

            v_pivot_sort_orders :=
                array_append(
                    v_pivot_sort_orders,
                    upper(
                        trim(
                            coalesce(
                                v_json_pivot->>'Sort_Order',
                                'ASC'
                            )
                        )
                    )
                );

            v_pivot_count := v_pivot_count + 1;

        END LOOP;

    END LOOP;

    ----------------------------------------------------------------------------
    -- Build Global Metadata
    ----------------------------------------------------------------------------

    FOR i IN 1 .. v_pivot_count
    LOOP

        v_pivot_field := v_pivot_fields[i];
        v_pivot_data  := v_pivot_datas[i];
        v_pivot_type  := v_pivot_types[i];

        IF v_pivot_data IS NOT NULL
        AND btrim(v_pivot_data) <> ''
        THEN

			------------------------------------------------------------------------
			-- Determine whether the pivot data column is numeric
			------------------------------------------------------------------------
			
			v_numeric_flags :=
			    array_append
			    (
			        v_numeric_flags,
			        0
			    );
			
			IF v_pivot_data IS NOT NULL
			AND btrim(v_pivot_data) <> ''
			THEN
			
			    DECLARE
			        v_sql        text;
			        v_data_type  text;
			    BEGIN
			
			        --------------------------------------------------------------------
			        -- Determine the datatype of the Pivot_Data column
			        --------------------------------------------------------------------
			
			        SELECT data_type
			        INTO v_data_type
			        FROM information_schema.columns
			        WHERE table_schema LIKE 'pg_temp%'
			          AND table_name   = 'ep_describe'
			          AND lower(column_name) = lower(v_pivot_data);
			
			        --------------------------------------------------------------------
			        -- Update numeric flag
			        --------------------------------------------------------------------
			
			        IF v_data_type IN
			        (
			            'smallint',
			            'integer',
			            'bigint',
			            'numeric',
			            'decimal',
			            'real',
			            'double precision'
			        )
			        THEN
			            v_numeric_flags[array_length(v_numeric_flags,1)] := 1;
			        END IF;

			    EXCEPTION
			        WHEN OTHERS THEN
			            NULL;
			    END;

			END IF;

        END IF;

        ------------------------------------------------------------------------
        -- Discover all distinct pivot values
        ------------------------------------------------------------------------

        v_pivot_discovery_sql :=
		    'SELECT DISTINCT '
		    || quote_ident(v_pivot_field)
		    || E'\nFROM\n('
		    || v_user_sql
		    || E'\n) AS ep_source'
		    || E'\nWHERE '
		    || quote_ident(v_pivot_field)
		    || ' IS NOT NULL'
		    || E'\nORDER BY '
            || quote_ident(v_pivot_field)
            || ' '
            || CASE
                WHEN upper(coalesce(v_pivot_sort_orders[i], 'ASC'))
                            IN ('ASC', 'DESC')
                THEN upper(v_pivot_sort_orders[i])
                ELSE 'ASC'
            END;

		OPEN c FOR EXECUTE v_pivot_discovery_sql;
		
		LOOP
		    FETCH c INTO v_value;
		    EXIT WHEN NOT FOUND;

			IF v_value IS NULL THEN
			    RAISE EXCEPTION
			    'Discovery returned NULL for pivot field %',
			    v_pivot_field;
			END IF;

            v_pivot_values :=
                array_append
                (
                    v_pivot_values,
                    v_value
                );

			IF v_debug THEN
			    RAISE NOTICE 'Pivot values: %',
			        array_to_string(v_pivot_values, ', ');
			END IF;

			v_pivot_value_numbers :=
			    array_append
			    (
			        v_pivot_value_numbers,
			        i
			    );

            v_pivot_value_count :=
                v_pivot_value_count + 1;

		END LOOP;
		
		CLOSE c;

    END LOOP;

	EXECUTE 'DROP VIEW IF EXISTS ep_describe';

    ----------------------------------------------------------------------------
    -- Build Dynamic SELECT and FROM
    ----------------------------------------------------------------------------

    v_pivot_alias := 1;
    v_first_pivot_value := 1;

    ---------------------------------------------------------
    -- SELECT HEADER
    ---------------------------------------------------------

    v_dynamic_select := 'SELECT';

    ---------------------------------------------------------
    -- FROM HEADER
    ---------------------------------------------------------

    v_dynamic_from :=
        'FROM'
        || E'\n(\n'
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
            || E'\n        '
            || quote_ident(v_group_fields[group_number]);

    END LOOP;

    v_dynamic_from :=
        v_dynamic_from
        || E'\n    FROM\n'
		|| '    ('
		|| E'\n'
		|| replace(
		       regexp_replace(
		           trim(v_user_sql),
		           E'\n[ \t]*\n+',
		           E'\n',
		           'g'
		       ),
		       E'\n',
		       E'\n    '
		   )
		|| E'\n'
        || '    ) AS ep_source'
        || E'\n'
        || ') AS ep'
        || E'\n';

	/* ------------------------------------------------------------------------------
	--
	-- TWO-PASS EASY PIVOT PROCESSING
	--
	-- PASS 1: Process pivots attached to any group
	-- PASS 2: Process pivots NOT attached to any group
	--
	--
	-- IF (@follows_field = @group_field AND @pass_counter = 0) OR
	--	((@follows_field IS NULL OR TRIM(@follows_field) = '') AND @pass_counter = 1)
	--	
	-------------------------------------------------------------------------------*/

	FOR pass_counter IN 0 .. 1
	LOOP

		-----------------------------------------------------
		-- Emit current group field
		-----------------------------------------------------
		IF pass_counter = 0 THEN

			IF v_dynamic_select <> 'SELECT' THEN

				v_dynamic_select :=
					v_dynamic_select
					|| ',';

			END IF;

		END IF;

		FOR group_number IN 1 .. v_group_count
		LOOP

			IF pass_counter = 0 THEN
				IF group_number > 1 THEN
				    v_dynamic_select :=
				        v_dynamic_select
				        || ',';
				
				END IF;
				
				v_dynamic_select :=
				    v_dynamic_select
				    || E'\n    ep.'
				    || quote_ident(v_group_fields[group_number]);
			END IF;

			FOR pivot_number IN 1 .. v_pivot_count
			LOOP

				---------------------------------------------------------
				-- Retrieve current pivot metadata
				---------------------------------------------------------

                v_pivot_field :=
                    v_pivot_fields[pivot_number];

                v_pivot_type :=
                    v_pivot_types[pivot_number];

                v_pivot_data :=
                    v_pivot_datas[pivot_number];

			    ---------------------------------------------------------
			    -- Translate aggregate name for this database
			    ---------------------------------------------------------
			
			    v_sql_pivot_type := upper(v_pivot_type);

				IF v_sql_pivot_type IS NULL THEN
				    v_sql_pivot_type := 'MAX';
				END IF;
	
			    IF v_sql_pivot_type = 'STDEV' THEN
			        v_sql_pivot_type := 'STDDEV';
			    END IF;

				IF
				(
					   upper(trim(coalesce(v_pivot_follows[pivot_number], '')))
					   =
					   upper(v_group_fields[group_number])
					   AND pass_counter = 0
				)
				OR
				(
					   trim(coalesce(v_pivot_follows[pivot_number], '')) = ''
					   AND pass_counter = 1
				)
				THEN

					---------------------------------------------------------
					-- CORE ENGINE
					---------------------------------------------------------

					FOR chip_number IN 1 .. v_pivot_value_count
					LOOP
					
						IF v_pivot_value_numbers[chip_number] <> pivot_number THEN
						    CONTINUE;
						END IF;

						IF upper(coalesce(v_pivot_type, '')) = 'COUNT'
						OR v_numeric_flags[pivot_number] > 0
						THEN
							v_dynamic_select :=
								   v_dynamic_select
								|| ','
								|| E'\n'
								|| '    COALESCE('
								|| 'p'
								|| v_pivot_alias
								|| '.'
								|| quote_ident(v_pivot_values[chip_number])
								|| ',0) AS '
								|| quote_ident(
									CASE
										WHEN v_pivot_type IS NULL
										THEN ''
										ELSE v_pivot_type || '_'
									END
									|| v_pivot_values[chip_number]
								);

						ELSIF v_pivot_data IS NULL THEN
						
							v_dynamic_select :=
								   v_dynamic_select
								|| ','
								|| E'\n'
								|| '    CASE'
								|| E'\n'
								|| '        WHEN COALESCE('
								|| 'p'
								|| v_pivot_alias
								|| '.'
								|| quote_ident(v_pivot_values[chip_number])
								|| ','
								|| quote_literal(v_pivot_falses[pivot_number])
								|| ') = '
								|| quote_literal(v_pivot_falses[pivot_number])
								|| ' THEN '
								|| quote_literal(v_pivot_falses[pivot_number])
								|| E'\n'
								|| '        ELSE '
								|| quote_literal(v_pivot_trues[pivot_number])
								|| E'\n'
								|| '    END AS '
								|| quote_ident(v_pivot_values[chip_number]);

						ELSE

							v_dynamic_select :=
							       v_dynamic_select
							    || ','
							    || E'\n'
							    || '    COALESCE('
							    || 'p'
							    || v_pivot_alias
							    || '.'
							    || quote_ident(v_pivot_values[chip_number])
							    || ','
							    || quote_literal('')
							    || ') AS '
							    || quote_ident(
							        CASE
							            WHEN v_pivot_types[pivot_number] IS NULL
							            THEN ''
							            ELSE v_pivot_types[pivot_number] || '_'
							        END
							        || v_pivot_values[chip_number]
							    );

						END IF;

					END LOOP;

					---------------------------------------------------------
					-- FROM generation
					---------------------------------------------------------

					v_dynamic_from :=
						v_dynamic_from
						|| E'\n'
						|| 'LEFT JOIN'
						|| E'\n'
						|| '('
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
							|| E'\n'
							|| '            '
							|| quote_ident(v_group_fields[join_group_number]);

					END LOOP;

					---------------------------------------------------------
					-- Aggregate / Crosstab generation
					---------------------------------------------------------
					v_dynamic_from :=
						v_dynamic_from
						|| ',';
						
					v_first_pivot_value := 1;

					FOR i IN 1 .. v_pivot_value_count
					LOOP

						IF v_pivot_value_numbers[i] <> pivot_number THEN
						    CONTINUE;
						END IF;

						IF v_first_pivot_value = 0 THEN

							v_dynamic_from :=
								v_dynamic_from
								|| ',';

						END IF;

						v_first_pivot_value := 0;

						v_dynamic_from :=
							v_dynamic_from
							|| E'\n'
							|| '        '
							|| v_sql_pivot_type
							|| '(CASE WHEN '
							|| quote_ident(v_pivot_field)
							|| '='''
							|| replace(v_pivot_values[i],'''','''''')
							|| ''' THEN ';

							IF v_pivot_data IS NULL THEN
							
							    v_dynamic_from :=
							        v_dynamic_from
							        || quote_ident(v_pivot_field);
							
							ELSE
							
							    v_dynamic_from :=
							        v_dynamic_from
							        || quote_ident(v_pivot_data);
							
							END IF;

						v_dynamic_from :=
							v_dynamic_from
							|| ' END) AS '
							|| quote_ident(v_pivot_values[i]);

					END LOOP;
	
					v_dynamic_from :=
						v_dynamic_from
						|| E'\n'
						|| '    FROM'
						|| E'\n'
						|| '    ('
						|| E'\n'
						|| replace(
								regexp_replace(
									trim(v_user_sql),
									E'\n[ \t]*\n+',
									E'\n',
									'g'
								),
								E'\n',
								E'\n    '
							)
						|| E'\n'
						|| '    ) AS q'
						|| E'\n'
						|| '    GROUP BY'
						|| E'\n';

					v_first_group := TRUE;

					FOR join_group_number IN 1 .. v_group_count
					LOOP

						IF NOT v_first_group THEN

							v_dynamic_from :=
								v_dynamic_from
								|| ',';

						END IF;

						v_first_group := FALSE;

						v_dynamic_from :=
							v_dynamic_from
							|| E'\n'
							|| '        '
							|| quote_ident(v_group_fields[join_group_number]);

					END LOOP;

					v_dynamic_from :=
						v_dynamic_from
						|| ') p'
						|| v_pivot_alias
						|| E'\n';

					FOR join_group_number IN 1 .. v_group_count
					LOOP

						IF join_group_number = 1 THEN

							v_dynamic_from :=
								v_dynamic_from
								|| 'ON p'
								|| v_pivot_alias
								|| '.'
								|| quote_ident(
									v_group_fields[join_group_number]
								)
								|| ' = ep.'
								|| quote_ident(
									v_group_fields[join_group_number]
								)
								|| E'\n';

						ELSE

							v_dynamic_from :=
								v_dynamic_from
								|| 'AND p'
								|| v_pivot_alias
								|| '.'
								|| quote_ident(
									v_group_fields[join_group_number]
								)
								|| ' = ep.'
								|| quote_ident(
									v_group_fields[join_group_number]
								)
								|| E'\n';

						END IF;

					END LOOP;

					v_pivot_alias :=
						v_pivot_alias + 1;

				END IF;

			END LOOP;

            IF pass_counter = 1 THEN
                EXIT;
            END IF;

		END LOOP;

	END LOOP;

    ----------------------------------------------------------------------------
    -- Build Dynamic ORDER BY
    ----------------------------------------------------------------------------

	v_dynamic_order_by :=
	    'ORDER BY'
	    || E'\n';

	v_first_group := TRUE;

    FOR r IN
    (
        SELECT
            g.group_field,
            COALESCE(o.order_field, 'ASC') AS order_field
        FROM
        (
            SELECT
                ordinality AS rn,
				trim(trim(both '"' from group_item::text)) AS group_field
            FROM
                jsonb_array_elements(v_json_configuration) cfg(config)
			CROSS JOIN LATERAL
			    jsonb_array_elements(config->'Group')
			    WITH ORDINALITY AS g(group_item, ordinality)
        ) g
        LEFT JOIN
        (
            SELECT
                ordinality AS rn,
                upper(trim(order_field)) AS order_field
            FROM
                jsonb_array_elements(v_json_configuration) cfg(config)
                CROSS JOIN LATERAL
                jsonb_array_elements_text(config->'Order')
                WITH ORDINALITY AS o(order_field, ordinality)
        ) o
        ON g.rn = o.rn
        ORDER BY
            g.rn
    )
    LOOP

        IF NOT v_first_group THEN

            v_dynamic_order_by :=
                v_dynamic_order_by
                || ','
                || E'\n';

        END IF;

        v_first_group := FALSE;

        v_dynamic_order_by :=
            v_dynamic_order_by
            || '    ep.'
            || quote_ident(r.group_field)
            || ' '
            || CASE
                WHEN r.order_field IN ('ASC', 'DESC')
                THEN r.order_field
                ELSE 'ASC'
            END;

    END LOOP;

    ----------------------------------------------------------------------------
    -- Build Final SQL
    ----------------------------------------------------------------------------

	IF v_debug THEN
	    RAISE NOTICE 'SELECT:%', E'\n' || v_dynamic_select;
	    RAISE NOTICE 'FROM:%', E'\n' || v_dynamic_from;
	    RAISE NOTICE 'ORDER BY:%', E'\n' || v_dynamic_order_by;
	END IF;

    v_final_sql :=
           v_dynamic_select
        || E'\n'
        || v_dynamic_from
        || E'\n'
        || v_dynamic_order_by
		|| ';';

    ----------------------------------------------------------------------------
    -- Normalize generated SQL formatting.
    ----------------------------------------------------------------------------

    -- Normalize line endings.
    v_final_sql := replace(v_final_sql, E'\r\n', E'\n');
    v_final_sql := replace(v_final_sql, E'\r',   E'\n');

    -- Collapse multiple blank lines.
    v_final_sql := regexp_replace(
        v_final_sql,
        E'\n[ \t]*\n+',
        E'\n',
        'g'
    );

    -- Remove leading/trailing whitespace.
    v_final_sql := trim(v_final_sql);

    ----------------------------------------------------------------------------
    -- Execute Final SQL
    ----------------------------------------------------------------------------

    IF v_generate_source_code_only THEN

		v_output :=
		    E'\n\n' ||
		    v_final_sql || E'\n';

		    v_output :=
		        replace(
		            replace(trim(v_output), E'\r\n', E'\n'),
		            E'\r',
		            E'\n'
		        );

	RAISE NOTICE '%', v_output;

    ELSE

        ------------------------------------------------------------------------
        -- Execute the generated SQL.
        --
        -- Unlike Oracle's DBMS_SQL.RETURN_RESULT(), PostgreSQL cannot return an
        -- arbitrary dynamic result set directly from an anonymous DO block.
        --
        -- The generated SQL is executed here. If this engine is later converted
        -- into a stored procedure or set-returning function, this is the only
        -- section that will need to change.
        ------------------------------------------------------------------------

        EXECUTE v_final_sql;

    END IF;

END;
$$