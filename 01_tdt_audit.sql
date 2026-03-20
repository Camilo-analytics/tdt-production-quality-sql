-- =============================================
-- 01_DATA_AUDIT: tdt_production_raw
-- Project: Production Quality Analysis — Torrens Defence Technologies 2023-2024
-- Author: Camilo B Martinez
-- Source: tdt_production_raw.csv
--         Imported to DBeaver without modifications
-- =============================================
-- FINDINGS SUMMARY:
--   Total rows          : 500
--   Duplicates          : 25 duplicate unit_ids (all appear 2 times)
--   Unique rows         : 475 (after deduplication)
--   Columns with blanks : operator_id (15), defect_type (166), unit_cost_aud (81)
--   Format issues       : unit_cost_aud, production_time_mins, production_date (8 formats)
--   Consistency issues  : product_line, shift, inspection_result, client
-- =============================================


-- -------------------------
-- 1. TOTAL ROWS
-- -------------------------
SELECT COUNT(*) FROM tdt_production_raw;
-- Result: 500


-- -------------------------
-- 2. BLANKS AND NULLS PER COLUMN
-- Note: DBeaver imported NULLs as empty strings ''
--       NULLIF used to detect them correctly
-- -------------------------
SELECT
    COUNT(*) - COUNT(NULLIF(unit_id,''))               as nulls_unit_id,
    COUNT(*) - COUNT(NULLIF(product_line,''))          as nulls_product_line,
    COUNT(*) - COUNT(NULLIF(component_type,''))        as nulls_component_type,
    COUNT(*) - COUNT(NULLIF(production_date,''))       as nulls_production_date,
    COUNT(*) - COUNT(NULLIF(shift,''))                 as nulls_shift,
    COUNT(*) - COUNT(NULLIF(operator_id,''))           as nulls_operator_id,
    COUNT(*) - COUNT(NULLIF(inspection_result,''))     as nulls_inspection_result,
    COUNT(*) - COUNT(NULLIF(defect_type,''))           as nulls_defect_type,
    COUNT(*) - COUNT(NULLIF(production_time_mins,''))  as nulls_production_time,
    COUNT(*) - COUNT(NULLIF(unit_cost_aud,''))         as nulls_unit_cost,
    COUNT(*) - COUNT(NULLIF(client,''))                as nulls_client,
    COUNT(*) - COUNT(NULLIF(line_id,''))               as nulls_line_id
FROM tdt_production_raw;
-- Result:
--   unit_id              : 0
--   product_line         : 0
--   component_type       : 0
--   production_date      : 0
--   shift                : 0
--   operator_id          : 15  -- blanks — replace with 'unknown'
--   inspection_result    : 0
--   defect_type          : 166 -- blanks — expected for passing units, replace with 'none'
--   production_time_mins : 0   -- text values and negatives — see section 5
--   unit_cost_aud        : 81  -- blanks — replace with NULL
--   client               : 0
--   line_id              : 0


-- -------------------------
-- 3. DUPLICATES
-- Identified by unit_id
-- -------------------------
SELECT unit_id, COUNT(*) as occurrences
FROM tdt_production_raw
GROUP BY unit_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;
-- Result: 25 duplicate unit_ids, all appearing 2 times
--   10013, 10014, 10016, 10017, 10045, 10048, 10053, 10058,
--   10072, 10112, 10115, 10120, 10126, 10141, 10217, 10259,
--   10280, 10288, 10303, 10309, 10328, 10347, 10378, 10380, 10457
-- Decision: keep MAX(rowid) per unit_id — 475 unique rows


-- -------------------------
-- 4. DISTINCT VALUES — CATEGORICAL COLUMNS
-- -------------------------

-- product_line: 10 variants of 3 valid values
SELECT DISTINCT product_line FROM tdt_production_raw ORDER BY product_line;
-- Issue: ANTENNA SYSTEM, Antenna System, antenna system
--        COMMS UNIT, Comms Unit, comms unit
--        RF ASSEMBLY, RF Assembly, RF assembly, rf assembly
-- Decision: normalize to RF Assembly / Antenna System / Comms Unit

-- component_type: 12 values, consistent casing — no action required
SELECT DISTINCT component_type FROM tdt_production_raw ORDER BY component_type;
-- Result: Control Interface, Dipole Antenna, Encryption Board, Frequency Converter,
--         Horn Antenna, Patch Antenna, Power Amplifier, Power Supply Unit,
--         RF Module, Signal Filter, Transceiver Module, Yagi Array

-- shift: 15 variants of 3 valid values
SELECT DISTINCT shift FROM tdt_production_raw ORDER BY shift;
-- Issue: MORNING, Morn, AM, morning
--        AFTERNOON, Aftn, PM, afternoon
--        NIGHT, Nght, PM-Night, night
-- Decision: normalize to Morning / Afternoon / Night

-- inspection_result: 10 variants of 3 valid values
SELECT DISTINCT inspection_result FROM tdt_production_raw ORDER BY inspection_result;
-- Issue: PASS, pass / FAIL, fail / REWORK, Re-work, rework
-- Decision: normalize to Pass / Fail / Rework

-- defect_type: multiple null representations
SELECT DISTINCT defect_type FROM tdt_production_raw ORDER BY defect_type;
-- Issue: '' (empty), 'None', 'N/A' all represent absence of defect
-- Decision: standardise all to 'none'

-- client: 15 variants of 3 valid values
SELECT DISTINCT client FROM tdt_production_raw ORDER BY client;
-- Issue: DEFENCE, Def, DEF, defence / MINING, Min, MIN, mining / EXPORT, Exp, EXP, export
-- Decision: normalize to Defence / Mining / Export

-- line_id: clean — no issues
SELECT DISTINCT line_id FROM tdt_production_raw ORDER BY line_id;
-- Result: Line A / Line B / Line C


-- -------------------------
-- 5. FORMAT ISSUES — PRODUCTION_TIME_MINS
-- -------------------------
SELECT DISTINCT production_time_mins FROM tdt_production_raw ORDER BY production_time_mins;
-- Issues identified:
--   forty-five, sixty, thirty, one-twenty, etc. — text values — convert to numeric
--   -60, -35, -50, -30                          — negative values — apply ABS()
--   N/A                                         — non-numeric string — set to NULL
--   0                                           — impossible production time — set to NULL
-- Decision: text to numeric, negatives to ABS(), N/A and 0 to NULL
--
-- Word-form mapping:
--   fifteen   -> 15    thirty      -> 30    forty-five  -> 45
--   twenty    -> 20    thirty-five -> 35    fifty       -> 50
--   twenty-five -> 25  forty       -> 40    sixty       -> 60
--   ninety    -> 90    one-twenty  -> 120


-- -------------------------
-- 6. FORMAT ISSUES — UNIT_COST_AUD
-- -------------------------
SELECT DISTINCT unit_cost_aud FROM tdt_production_raw LIMIT 20;
-- Issues identified:
--   ($2,065.27)  — accounting negative with thousands separator
--   $864.11      — dollar sign prefix
--   1,717.20     — thousands separator without symbol
--   N/A          — non-numeric string — set to NULL
--   ''           — empty string — set to NULL
-- Decision: remove $, remove commas, convert () to negative sign, N/A and blanks to NULL


-- -------------------------
-- 7. FORMAT ISSUES — PRODUCTION_DATE (8 formats detected)
-- -------------------------
SELECT DISTINCT production_date FROM tdt_production_raw LIMIT 20;
-- Formats identified:
--   YYYY-MM-DD         — ISO 8601              e.g. 2024-07-29       — no change needed
--   DD-Mon-YY          — abbreviated month     e.g. 06-Mar-24
--   DD-MM-YYYY         — dash separator        e.g. 30-04-2024
--   DD/MM/YYYY         — slash separator       e.g. 17/03/2024
--   DD.MM.YYYY         — dot separator         e.g. 19.11.2024
--   D/M/YYYY           — single digit day/month e.g. 3/9/2024
--   D/MM/YYYY          — single digit day       e.g. 1/03/2024
--   DD/M/YYYY          — single digit month     e.g. 26/6/2023
--   Month DD, YYYY     — long text format       e.g. December 20, 2023
-- Decision: convert all to ISO 8601 (YYYY-MM-DD)
--           ambiguous dates resolved using AU convention (DD first)
