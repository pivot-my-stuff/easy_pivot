----------------------------------------------------------------------------
-- Example: Follows_Group Pivot
----------------------------------------------------------------------------
--
-- Demonstrates Easy Pivot's Follows_Group option.
--
-- This example places generated pivot columns immediately after
-- selected Group fields instead of after all Group fields.
--
-- Group:
--
--     tableowner
--     tablespace
--
-- Pivot:
--
--     schemaname
--     hasindexes
--
-- Demonstrates:
--
--     Follows_Group
--     Multiple pivot definitions
--     Boolean pivot
--     Aggregate pivot
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
FROM pg_tables

$SQL$;


v_json_configuration JSONB := $JSON$

[
  {
    "Group": ["tableowner", "tablespace"],
	
    "Order": ["ASC", "ASC"],
	
    "Pivot": [
	     {"Pivot_Field": "schemaname", "Pivot_Type": "Count", "Pivot_Data": "tablename", "Follows_Group": "tableowner"}
	    ,{"Pivot_Field": "hasindexes", "Pivot_Type": "Max", "Pivot_True": "Yes", "Pivot_False": "No", "Follows_Group": "tablespace"}
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
v_pivot_value_fields       TEXT[] := ARRAY[]::TEXT[];

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

v_output                  TEXT;

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
    v_pivot_types        := ARRAY[]::TEXT[];
    v_pivot_datas        := ARRAY[]::TEXT[];
    v_pivot_trues        := ARRAY[]::TEXT[];
    v_pivot_falses       := ARRAY[]::TEXT[];
    v_pivot_follows      := ARRAY[]::TEXT[];
    v_pivot_sort_orders  := ARRAY[]::TEXT[];

    v_pivot_values       := ARRAY[]::TEXT[];
    v_pivot_value_fields := ARRAY[]::TEXT[];

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
    -- Discover Pivot Metadata
    ----------------------------------------------------------------------------

    FOR i IN 1 .. v_pivot_count
    LOOP

        v_pivot_field := v_pivot_fields[i];
        v_pivot_data  := v_pivot_datas[i];
        v_pivot_type  := v_pivot_types[i];

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

            /*
            * TODO:
            * Replace this placeholder with the PostgreSQL equivalent of
            * Oracle's is_numeric_column() logic.
            */

        END IF;

        ------------------------------------------------------------------------
        -- Discover all distinct pivot values
        ------------------------------------------------------------------------

        v_pivot_discovery_sql :=
            'SELECT DISTINCT '
            || quote_ident(v_pivot_field)
            || E'\nFROM\n('
            || v_user_sql
            || E'\n) AS ep_source\nORDER BY '
            || quote_ident(v_pivot_field)
            || ' '
            || CASE
                WHEN upper(coalesce(v_pivot_sort_orders[i], 'ASC'))
                            IN ('ASC', 'DESC')
                THEN upper(v_pivot_sort_orders[i])
                ELSE 'ASC'
            END;

        FOR v_value IN EXECUTE v_pivot_discovery_sql
        LOOP

            v_pivot_values :=
                array_append
                (
                    v_pivot_values,
                    v_value
                );

            v_pivot_value_fields :=
                array_append
                (
                    v_pivot_value_fields,
                    v_pivot_field
                );

            v_pivot_value_count :=
                v_pivot_value_count + 1;

        END LOOP;

    END LOOP;

    ----------------------------------------------------------------------------
    -- Build SELECT/FROM (Follows_Group)
    ----------------------------------------------------------------------------

/*

    FOR i IN 1 .. v_pivot_value_count
    LOOP

        -- Skip pivot values that are not associated with a Follows_Group.

        IF coalesce(trim(v_pivot_follows[i]), '') = '' THEN
            CONTINUE;
        END IF;

        ------------------------------------------------------------------------
        -- Locate the requested group field.
        ------------------------------------------------------------------------

        FOR j IN 1 .. v_group_count
        LOOP

            IF upper(v_group_fields[j]) <> upper(v_pivot_follows[i]) THEN
                CONTINUE;
            END IF;

            --------------------------------------------------------------------
            -- Build SELECT expression.
            --------------------------------------------------------------------

			v_dynamic_select :=
			    v_dynamic_select
			    || E',\n'
			    || '    '
			    || v_pivot_types[pivot_number]
			    || '(CASE WHEN '
			    || quote_ident(v_pivot_fields[pivot_number])
			    || ' = '
			    || quote_literal(v_pivot_values[i])
			    || ' THEN '
			    || quote_ident(v_pivot_datas[pivot_number])
			    || ' END) AS '
			    || quote_ident(v_pivot_values[i]);

            --------------------------------------------------------------------
            -- Build FROM expression (if required).
            --------------------------------------------------------------------

            v_dynamic_from :=
                v_dynamic_from
                || '';

            EXIT;

        END LOOP;

    END LOOP;

*/
    ----------------------------------------------------------------------------
    -- Load Pivot Metadata
    ----------------------------------------------------------------------------

    v_group_count := 0;

    ----------------------------------------------------------------------------
    -- Load Group Fields
    ----------------------------------------------------------------------------

	FOR r IN
	(
	    SELECT
			trim(trim(both '"' from group_item::text)) AS group_field
	    FROM jsonb_to_recordset(v_json_configuration)
	    AS cfg
	    (
	        "Group" jsonb,
	        "Order" jsonb,
	        "Pivot" jsonb
	    )
		CROSS JOIN LATERAL
		    jsonb_array_elements(cfg."Group")
		    AS g(group_item)
	)
	LOOP

        v_group_count := v_group_count + 1;

        v_group_fields :=
            array_append
            (
                v_group_fields,
                r.group_field
            );

    END LOOP;

    ----------------------------------------------------------------------------
    -- Load Pivot Definitions
    ----------------------------------------------------------------------------

    v_pivot_count := 0;

    FOR r IN
    (
        SELECT

            ordinality AS pivot_position,

            trim(pivot_item->>'Pivot_Field')                      AS pivot_field,

            NULLIF(trim(pivot_item->>'Pivot_Data'), '')           AS pivot_data,

            coalesce
            (
                NULLIF(trim(pivot_item->>'Pivot_True'), ''),
                ''
            )                                                     AS pivot_true,

            coalesce
            (
                NULLIF(trim(pivot_item->>'Pivot_False'), ''),
                ''
            )                                                     AS pivot_false,

            trim(pivot_item->>'Pivot_Type')                       AS pivot_type,

            coalesce
            (
                NULLIF(trim(pivot_item->>'Follows_Group'), ''),
                NULLIF(trim(pivot_item->>'Follows_Field'), '')
            )                                                     AS follows_field,

            coalesce
            (
                NULLIF(trim(pivot_item->>'Sort_Order'), ''),
                'ASC'
            )                                                     AS sort_order

        FROM jsonb_array_elements(v_json_configuration) cfg(config)

        CROSS JOIN LATERAL
            jsonb_array_elements(config->'Pivot')
            WITH ORDINALITY
            AS p(pivot_item, ordinality)

        ORDER BY
            pivot_position
    )
    LOOP

        v_pivot_count := v_pivot_count + 1;

        v_pivot_fields :=
            array_append
            (
                v_pivot_fields,
                r.pivot_field
            );

        v_pivot_datas :=
            array_append
            (
                v_pivot_datas,
                r.pivot_data
            );

        v_pivot_types :=
            array_append
            (
                v_pivot_types,
                r.pivot_type
            );

        v_pivot_trues :=
            array_append
            (
                v_pivot_trues,
                r.pivot_true
            );

        v_pivot_falses :=
            array_append
            (
                v_pivot_falses,
                r.pivot_false
            );

        v_pivot_follows :=
            array_append
            (
                v_pivot_follows,
                r.follows_field
            );

        v_pivot_sort_orders :=
            array_append
            (
                v_pivot_sort_orders,
                r.sort_order
            );

    END LOOP;

    ----------------------------------------------------------------------------
    -- Determine Pivot Data Types
    ----------------------------------------------------------------------------

    IF v_pivot_count > 0 THEN

        FOR pivot_number IN 1 .. v_pivot_count
        LOOP

            v_pivot_field :=
                v_pivot_fields[pivot_number];

            v_pivot_data :=
                v_pivot_datas[pivot_number];

            v_pivot_type :=
                v_pivot_types[pivot_number];

            v_numeric_flags[pivot_number] := 0;

            IF v_pivot_data IS NOT NULL THEN

                -- PostgreSQL equivalent of Oracle's
                -- is_numeric_column() will be inlined here.

                ----------------------------------------------------------------
                -- Determine whether the Pivot_Data column is numeric.
                ----------------------------------------------------------------

                v_numeric_detection_sql :=
                    'SELECT pg_typeof('
                    || quote_ident(v_pivot_data)
                    || ')::text '
                    || E'\nFROM (\n'
                    || v_user_sql
                    || E'\n) AS ep_source\n'
                    || 'LIMIT 1';

                BEGIN

                    EXECUTE v_numeric_detection_sql
                    INTO v_detected_type;

					IF lower(v_detected_type) IN
					(
					    'smallint',
					    'integer',
					    'bigint',
					    'numeric',
					    'real',
					    'double precision',
					    'decimal'
					)
					THEN
					
					    v_numeric_flags[pivot_number] := 1;
					
					ELSE
					
					    v_numeric_flags[pivot_number] := 0;
					
					END IF;

                EXCEPTION
                    WHEN OTHERS THEN

                        /*
                            Behave like the Oracle implementation.
                            If metadata inspection fails, assume the
                            column is not numeric and continue.
                        */

                        v_numeric_flags[pivot_number] := 0;

                END;

            END IF;

        END LOOP;

    END IF;

    ----------------------------------------------------------------------------
    -- Discover Distinct Pivot Values
    ----------------------------------------------------------------------------

    v_pivot_value_count := 0;

    FOR pivot_number IN 1 .. v_pivot_count
    LOOP

        v_pivot_field := v_pivot_fields[pivot_number];

        v_pivot_discovery_sql :=
            'SELECT DISTINCT '
            || quote_ident(v_pivot_field)
            || E'\nFROM\n'
			|| E'\n(\n'
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
            || E'\n) AS ep_source\n'
            || 'ORDER BY '
            || quote_ident(v_pivot_field)
            || ' '
            || CASE
                WHEN upper(v_pivot_sort_orders[pivot_number])
                        IN ('ASC', 'DESC')
                THEN upper(v_pivot_sort_orders[pivot_number])
                ELSE 'ASC'
            END;

        FOR v_pivot_value IN EXECUTE v_pivot_discovery_sql
        LOOP

            v_duplicate_found := FALSE;

            FOR existing_chip IN 1 .. v_pivot_value_count
            LOOP

                IF v_pivot_values[existing_chip] = v_pivot_value
                AND
                v_pivot_value_fields[existing_chip] = v_pivot_field
                THEN
                    v_duplicate_found := TRUE;
                    EXIT;
                END IF;

            END LOOP;

            IF NOT v_duplicate_found THEN

                v_pivot_value_count :=
                    v_pivot_value_count + 1;

                v_pivot_values :=
                    array_append
                    (
                        v_pivot_values,
                        v_pivot_value
                    );

                v_pivot_value_fields :=
                    array_append
                    (
                        v_pivot_value_fields,
                        v_pivot_field
                    );

            END IF;

        END LOOP;

    END LOOP;


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
                -- Load current pivot metadata
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
			
			    IF v_sql_pivot_type = 'STDEV' THEN
			        v_sql_pivot_type := 'STDDEV';
			    END IF;

                ---------------------------------------------------------
                -- Discover THIS pivot's values
                ---------------------------------------------------------

                v_pivot_values :=
                    ARRAY[]::TEXT[];

                v_pivot_value_count := 0;

                v_pivot_discovery_sql :=
                    'SELECT DISTINCT '
                    || quote_ident(v_pivot_field)
                    || E'\nFROM\n'
                    || E'(\n'
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
                    || E'\n) AS ep_source\n'
                    || 'ORDER BY '
                    || quote_ident(v_pivot_field)
                    || ' '
                    || CASE
                           WHEN upper(coalesce(v_pivot_sort_orders[pivot_number],'ASC'))
                                IN ('ASC','DESC')
                           THEN upper(v_pivot_sort_orders[pivot_number])
                           ELSE 'ASC'
                       END;

                FOR v_pivot_value IN EXECUTE v_pivot_discovery_sql
                LOOP

                    v_pivot_value_count :=
                        v_pivot_value_count + 1;

                    v_pivot_values :=
                        array_append
                        (
                            v_pivot_values,
                            v_pivot_value
                        );

                END LOOP;

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

						IF upper(coalesce(v_pivot_types[pivot_number], '')) = 'COUNT'
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
										WHEN v_pivot_types[pivot_number] IS NULL
										THEN ''
										ELSE v_pivot_types[pivot_number] || '_'
									END
									|| v_pivot_values[chip_number]
								);

						ELSIF v_pivot_datas[pivot_number] IS NULL THEN

							v_dynamic_select :=
								   v_dynamic_select
								|| ','
								|| E'\n'
								|| '    COALESCE('
								|| 'p'
								|| v_pivot_alias
								|| '.'
								|| quote_ident(v_pivot_values[chip_number])
								|| ','''') AS '
								|| quote_ident(
									CASE
										WHEN v_pivot_types[pivot_number] IS NULL
										THEN ''
										ELSE v_pivot_types[pivot_number] || '_'
									END
									|| v_pivot_values[chip_number]
								);

						ELSE

							v_dynamic_select :=
								   v_dynamic_select
								|| ','
								|| E'\n'
								|| '    p'
								|| v_pivot_alias
								|| '.'
								|| quote_ident(v_pivot_values[chip_number])
								|| ' AS '
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
						|| ','
;
					v_first_pivot_value := 1;

					FOR i IN 1 .. v_pivot_value_count
					LOOP

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
							|| quote_ident(v_pivot_fields[pivot_number])
							|| '='''
							|| replace(v_pivot_values[i],'''','''''')
							|| ''' THEN ';

						IF v_pivot_datas[pivot_number] IS NULL THEN

							IF v_pivot_datas[pivot_number] IS NULL THEN
							
								v_dynamic_from :=
									v_dynamic_from
									|| quote_ident(v_pivot_fields[pivot_number]);
							
							ELSE
							
								v_dynamic_from :=
									v_dynamic_from
									|| quote_ident(v_pivot_datas[pivot_number]);
							
							END IF;

						ELSE

							v_dynamic_from :=
								v_dynamic_from
								|| quote_ident(v_pivot_datas[pivot_number]);

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