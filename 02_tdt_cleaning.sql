-- =============================================================================
-- FILE:    02_tdt_cleaning.sql
-- PURPOSE: Clean and standardise tdt_production_raw into an analysis-ready view
-- AUTHOR:  Camilo B Martinez
-- =============================================================================
-- ISSUES ADDRESSED:
--   1. product_line  → Inconsistent casing (10 variants → 3 categories)
--   2. production_date → Mixed date formats (8+ formats → ISO 8601 YYYY-MM-DD)
--   3. shift         → Inconsistent casing & abbreviations (15 variants → 3)
--   4. operator_id   → Empty strings → 'unknown'
--   5. inspection_result → Inconsistent casing & abbreviations (10 variants → 3)
--   6. defect_type   → Multiple null representations → 'none'
--   7. production_time_mins → Negatives, word-forms, nulls → clean INTEGER
--   8. unit_cost_aud → Currency symbols, parentheses, commas, nulls → DECIMAL
--   9. client        → Inconsistent casing & abbreviations (15 variants → 3)
-- =============================================================================

SELECT

    -- -------------------------------------------------------------------------
    -- unit_id: No transformation applied.
    -- NOTE: 25 duplicate unit_ids detected — deduplication strategy 
    --       requires business rule definition before acting.
    -- -------------------------------------------------------------------------
    unit_id,

    -- -------------------------------------------------------------------------
    -- product_line: Normalise 10 raw variants to 3 standard categories.
    -- Matching on lowercase prefix to capture all casing combinations.
    -- -------------------------------------------------------------------------
    CASE
        WHEN lower(product_line) LIKE 'rf%'  THEN 'RF Assembly'
        WHEN lower(product_line) LIKE 'ant%' THEN 'Antenna System'
        WHEN lower(product_line) LIKE 'com%' THEN 'Comms Unit'
    END AS product_line,

    -- -------------------------------------------------------------------------
    -- component_type: No transformation needed — values are consistent.
    -- -------------------------------------------------------------------------
    component_type,

    -- -------------------------------------------------------------------------
    -- production_date: Normalise 8+ mixed date formats to ISO 8601 (YYYY-MM-DD)
    --
    -- Formats handled:
    --   [A] ISO 8601           e.g. 2024-07-29          → no change needed
    --   [B] DD-Mon-YY          e.g. 06-Mar-24            → 2024-03-06
    --   [C] DD-MM-YYYY         e.g. 30-04-2024           → 2024-04-30
    --   [D] DD.MM.YYYY         e.g. 19.11.2024           → 2024-11-19
    --   [E] D/M/YYYY           e.g. 3/9/2024             → 2024-09-03
    --   [F] D/MM/YYYY          e.g. 1/03/2024            → 2024-03-01
    --   [G] DD/M/YYYY          e.g. 26/6/2023            → 2023-06-26
    --   [H] DD/MM/YYYY         e.g. 17/03/2024           → 2024-03-17
    --   [I] Month DD, YYYY     e.g. December 20, 2023    → 2023-12-20
    -- -------------------------------------------------------------------------
    CASE
        -- [A] ISO 8601: YYYY-MM-DD — already correct, pass through
        WHEN substr(production_date, 5, 1) = '-'
            THEN production_date

        -- [B] DD-Mon-YY — e.g. 06-Mar-24
        WHEN production_date GLOB '[0-9][0-9]-[a-zA-Z]*'
            THEN CASE substr(lower(production_date), 4, 3)
                WHEN 'jan' THEN '20'||substr(production_date,-2)||'-01-'||substr(production_date,1,2)
                WHEN 'feb' THEN '20'||substr(production_date,-2)||'-02-'||substr(production_date,1,2)
                WHEN 'mar' THEN '20'||substr(production_date,-2)||'-03-'||substr(production_date,1,2)
                WHEN 'apr' THEN '20'||substr(production_date,-2)||'-04-'||substr(production_date,1,2)
                WHEN 'may' THEN '20'||substr(production_date,-2)||'-05-'||substr(production_date,1,2)
                WHEN 'jun' THEN '20'||substr(production_date,-2)||'-06-'||substr(production_date,1,2)
                WHEN 'jul' THEN '20'||substr(production_date,-2)||'-07-'||substr(production_date,1,2)
                WHEN 'aug' THEN '20'||substr(production_date,-2)||'-08-'||substr(production_date,1,2)
                WHEN 'sep' THEN '20'||substr(production_date,-2)||'-09-'||substr(production_date,1,2)
                WHEN 'oct' THEN '20'||substr(production_date,-2)||'-10-'||substr(production_date,1,2)
                WHEN 'nov' THEN '20'||substr(production_date,-2)||'-11-'||substr(production_date,1,2)
                WHEN 'dec' THEN '20'||substr(production_date,-2)||'-12-'||substr(production_date,1,2)
            END

        -- [C] DD-MM-YYYY — e.g. 30-04-2024
        WHEN substr(production_date, 3, 1) = '-'
            THEN substr(production_date,-4)||'-'||substr(production_date,4,2)||'-'||substr(production_date,1,2)

        -- [D] DD.MM.YYYY — e.g. 19.11.2024
        WHEN production_date GLOB '*.*'
            THEN substr(production_date,-4)||'-'||substr(production_date,4,2)||'-'||substr(production_date,1,2)

        -- [E] D/M/YYYY — single-digit day AND month, e.g. 3/9/2024
        WHEN production_date LIKE '_/_/____'
            THEN CASE substr(production_date, 3, 1)
                WHEN '1' THEN substr(production_date,-4)||'-01-0'||substr(production_date,1,1)
                WHEN '2' THEN substr(production_date,-4)||'-02-0'||substr(production_date,1,1)
                WHEN '3' THEN substr(production_date,-4)||'-03-0'||substr(production_date,1,1)
                WHEN '4' THEN substr(production_date,-4)||'-04-0'||substr(production_date,1,1)
                WHEN '5' THEN substr(production_date,-4)||'-05-0'||substr(production_date,1,1)
                WHEN '6' THEN substr(production_date,-4)||'-06-0'||substr(production_date,1,1)
                WHEN '7' THEN substr(production_date,-4)||'-07-0'||substr(production_date,1,1)
                WHEN '8' THEN substr(production_date,-4)||'-08-0'||substr(production_date,1,1)
                WHEN '9' THEN substr(production_date,-4)||'-09-0'||substr(production_date,1,1)
            END

        -- [F] D/MM/YYYY — single-digit day, two-digit month, e.g. 1/03/2024
        WHEN production_date LIKE '_/__/____'
            THEN substr(production_date,-4)||'-'||substr(production_date,3,2)||'-0'||substr(production_date,1,1)

        -- [G] DD/M/YYYY — two-digit day, single-digit month, e.g. 26/6/2023
        WHEN production_date LIKE '__/_/____'
            THEN CASE substr(production_date, 4, 1)
                WHEN '1' THEN substr(production_date,-4)||'-01-'||substr(production_date,1,2)
                WHEN '2' THEN substr(production_date,-4)||'-02-'||substr(production_date,1,2)
                WHEN '3' THEN substr(production_date,-4)||'-03-'||substr(production_date,1,2)
                WHEN '4' THEN substr(production_date,-4)||'-04-'||substr(production_date,1,2)
                WHEN '5' THEN substr(production_date,-4)||'-05-'||substr(production_date,1,2)
                WHEN '6' THEN substr(production_date,-4)||'-06-'||substr(production_date,1,2)
                WHEN '7' THEN substr(production_date,-4)||'-07-'||substr(production_date,1,2)
                WHEN '8' THEN substr(production_date,-4)||'-08-'||substr(production_date,1,2)
                WHEN '9' THEN substr(production_date,-4)||'-09-'||substr(production_date,1,2)
            END

        -- [H] DD/MM/YYYY — two-digit day and month, e.g. 17/03/2024
        WHEN production_date LIKE '__/__/____'
            THEN substr(production_date,-4)||'-'||substr(production_date,4,2)||'-'||substr(production_date,1,2)

        -- [I] Month DD, YYYY — e.g. December 20, 2023
        WHEN production_date GLOB '[a-zA-Z]*'
            THEN CASE substr(lower(production_date), 1, 3)
                WHEN 'jan' THEN substr(production_date,-4)||'-01-'||substr(production_date,-8,2)
                WHEN 'feb' THEN substr(production_date,-4)||'-02-'||substr(production_date,-8,2)
                WHEN 'mar' THEN substr(production_date,-4)||'-03-'||substr(production_date,-8,2)
                WHEN 'apr' THEN substr(production_date,-4)||'-04-'||substr(production_date,-8,2)
                WHEN 'may' THEN substr(production_date,-4)||'-05-'||substr(production_date,-8,2)
                WHEN 'jun' THEN substr(production_date,-4)||'-06-'||substr(production_date,-8,2)
                WHEN 'jul' THEN substr(production_date,-4)||'-07-'||substr(production_date,-8,2)
                WHEN 'aug' THEN substr(production_date,-4)||'-08-'||substr(production_date,-8,2)
                WHEN 'sep' THEN substr(production_date,-4)||'-09-'||substr(production_date,-8,2)
                WHEN 'oct' THEN substr(production_date,-4)||'-10-'||substr(production_date,-8,2)
                WHEN 'nov' THEN substr(production_date,-4)||'-11-'||substr(production_date,-8,2)
                WHEN 'dec' THEN substr(production_date,-4)||'-12-'||substr(production_date,-8,2)
            END

    END AS production_date,

    -- -------------------------------------------------------------------------
    -- shift: Normalise 15 raw variants to 3 standard shift names.
    -- Priority: check 'PM-Night' (contains both PM and Night) before PM alone.
    -- -------------------------------------------------------------------------
    CASE
        WHEN lower(shift) LIKE 'mor%' OR lower(shift) = 'am'          THEN 'Morning'
        WHEN lower(shift) LIKE 'pm%' AND lower(shift) LIKE '%ght'     THEN 'Night'
        WHEN lower(shift) LIKE 'aft%' OR lower(shift) LIKE 'pm%'      THEN 'Afternoon'
        WHEN lower(shift) LIKE '%ht' OR lower(shift) LIKE '%ght'      THEN 'Night'
    END AS shift,

    -- -------------------------------------------------------------------------
    -- operator_id: Replace empty strings with 'unknown' for traceability.
    -- -------------------------------------------------------------------------
    CASE
        WHEN trim(operator_id) = '' THEN 'unknown'
        ELSE operator_id
    END AS operator_id,

    -- -------------------------------------------------------------------------
    -- inspection_result: Normalise 10 variants to 3 standard outcomes.
    -- -------------------------------------------------------------------------
    CASE
        WHEN lower(inspection_result) LIKE 'pass%'  THEN 'Pass'
        WHEN lower(inspection_result) LIKE 'fail%'  THEN 'Fail'
        WHEN lower(inspection_result) LIKE '%ork'
          OR lower(inspection_result) LIKE 're-%'   THEN 'Rework'
    END AS inspection_result,

    -- -------------------------------------------------------------------------
    -- defect_type: Standardise all "no defect" representations to 'none'.
    -- Affected raw values: '' (empty), 'None', 'N/A'
    -- -------------------------------------------------------------------------
    CASE
        WHEN lower(trim(defect_type)) IN ('', 'none', 'n/a') THEN 'none'
        ELSE defect_type
    END AS defect_type,

    -- -------------------------------------------------------------------------
    -- production_time_mins: Clean to a positive INTEGER value.
    --   - Null representations (N/A, 0, empty) → NULL
    --   - Word-form numbers                     → INTEGER equivalent
    --   - Negative numeric values               → ABS() applied
    --   - Valid numeric strings                 → CAST to INTEGER
    -- -------------------------------------------------------------------------
    CASE
        WHEN lower(trim(production_time_mins)) IN ('n/a', '0', '') THEN NULL
        WHEN lower(production_time_mins) = 'forty-five'            THEN 45
        WHEN lower(production_time_mins) = 'one-twenty'            THEN 120
        WHEN lower(production_time_mins) = 'sixty'                 THEN 60
        WHEN lower(production_time_mins) = 'thirty'                THEN 30
        WHEN lower(production_time_mins) = 'twenty'                THEN 20
        WHEN lower(production_time_mins) = 'ninety'                THEN 90
        WHEN lower(production_time_mins) = 'forty'                 THEN 40
        WHEN lower(production_time_mins) = 'fifteen'               THEN 15
        WHEN lower(production_time_mins) = 'fifty'                 THEN 50
        WHEN lower(production_time_mins) = 'thirty-five'           THEN 35
        WHEN lower(production_time_mins) = 'twenty-five'           THEN 25
        ELSE ABS(CAST(production_time_mins AS INTEGER))
    END AS production_time_mins,

    -- -------------------------------------------------------------------------
    -- unit_cost_aud: Parse text-formatted currency to DECIMAL.
    --   - Strip '$' prefix
    --   - Remove ',' thousands separator
    --   - Convert accounting negatives: '(1760.95)' → '-1760.95'
    --   - Null representations ('', 'N/A', 'null') → NULL
    -- -------------------------------------------------------------------------
    CASE
        WHEN lower(trim(unit_cost_aud)) IN ('n/a', '', 'null') THEN NULL
        ELSE CAST(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(unit_cost_aud, '$', ''),
                    ',', ''),
                '(', '-'),
            ')', '')
        AS DECIMAL)
    END AS unit_cost_aud,

    -- -------------------------------------------------------------------------
    -- client: Normalise 15 raw variants to 3 standard client names.
    -- -------------------------------------------------------------------------
    CASE
        WHEN lower(client) LIKE 'def%' THEN 'Defence'
        WHEN lower(client) LIKE 'min%' THEN 'Mining'
        WHEN lower(client) LIKE 'exp%' THEN 'Export'
        ELSE 'Other'
    END AS client,

    -- -------------------------------------------------------------------------
    -- line_id: No transformation needed — values are consistent.
    -- -------------------------------------------------------------------------
    line_id

FROM tdt_production_raw
-- user_id: eliminating duplicates
WHERE rowid IN (
    SELECT MAX(rowid)
    FROM tdt_production_raw
    GROUP BY unit_id
);

-- =============================================================================
-- TO CREATE THE CLEAN TABLE: Run the SELECT statement above wrapped in:
-- CREATE TABLE tdt_production_clean AS [full SELECT above]
-- =============================================================================
