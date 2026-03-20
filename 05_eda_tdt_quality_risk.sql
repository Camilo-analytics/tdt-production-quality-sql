-- ============================================================
-- 05_eda_tdt_quality_risk.sql
-- Project: Production Quality & Defect Analysis
-- Torrens Defence Technologies 2023–2024
-- ============================================================
-- BUSINESS BRIEF (Sarah Chen, Production Manager):
-- "We need to understand where our quality problems are concentrated —
-- which lines, shifts, operators and product types represent the
-- highest risk of defects and rework?"
--
-- ANALYST QUESTIONS:
-- Q1: What is the fail/rework rate by product_line, shift, and line_id?
-- Q2: Which defect types are most frequent — and in which component types?
-- Q3: Which operators have a non-pass rate above 30%?
-- Q4: Is there temporal concentration of defects by quarter?
--
-- HYPOTHESIS:
-- "What production patterns and factors are associated with failed
-- and rework units at TDT — and which operators, lines, and product
-- types represent the highest quality risk?"
--
-- NOTE: Dataset is synthetic (500 rows). Findings are indicative only.
-- operator_id has 15 unknown records — operator analysis is approximate.
-- ============================================================
-- Q1a: Fail and rework rate by line_id
-- ============================================================
-- FINDING: All three lines show comparable defect rates, but Line A
-- has the highest fail rate (23.1%) and Line B the highest rework rate (18.0%).
-- No single line is dramatically worse, but Line A represents the
-- highest risk of units failing final inspection.
-- ============================================================
with base as (
   select line_id,
          sum(
             case
                when inspection_result = 'Pass' then
                   1
                else
                   0
             end
          ) as pass,
          sum(
             case
                when inspection_result = 'Fail' then
                   1
                else
                   0
             end
          ) as fails,
          sum(
             case
                when inspection_result = 'Rework' then
                   1
                else
                   0
             end
          ) as reworks
     from tdt_production_clean
    group by line_id
)
select line_id,
       round(
          fails * 100.0 /(pass + fails + reworks),
          1
       ) as fail_rate,
       round(
          reworks * 100.0 /(pass + fails + reworks),
          1
       ) as rework_rate
  from base
 group by line_id
 order by fail_rate desc;
-- Q1b: Fail and rework rate by shift
-- ============================================================
-- FINDING: Morning shift has the highest fail rate (23.1%) matching
-- Line A's fail rate exactly — consistent with the earlier observation
-- of Line A RF Assembly Morning as a high-risk combination (50% fail rate).
-- Night shift shows the lowest rework rate (13.7%).
-- ============================================================
with base as (
   select shift,
          sum(
             case
                when inspection_result = 'Pass' then
                   1
                else
                   0
             end
          ) as pass,
          sum(
             case
                when inspection_result = 'Fail' then
                   1
                else
                   0
             end
          ) as fails,
          sum(
             case
                when inspection_result = 'Rework' then
                   1
                else
                   0
             end
          ) as reworks
     from tdt_production_clean
    group by shift
)
select shift,
       round(
          fails * 100.0 /(pass + fails + reworks),
          1
       ) as fail_rate,
       round(
          reworks * 100.0 /(pass + fails + reworks),
          1
       ) as rework_rate
  from base
 group by shift
 order by fail_rate desc;
-- Q1c: Fail and rework rate by line_id + shift combination
-- ============================================================
-- FINDING: Line A Morning is the highest risk combination (26.0% fail rate)
-- confirming the pattern observed in Q1a and Q1b. However Line B Morning
-- (24.6%) is close behind — Morning shift is consistently problematic
-- across all three lines. One exception: Line B Afternoon shows the
-- lowest fail rate (10.6%) but highest rework rate (21.3%), suggesting
-- strong in-process correction before final inspection.
-- ============================================================
with base as (
   select line_id,
          shift,
          sum(
             case
                when inspection_result = 'Pass' then
                   1
                else
                   0
             end
          ) as pass,
          sum(
             case
                when inspection_result = 'Fail' then
                   1
                else
                   0
             end
          ) as fails,
          sum(
             case
                when inspection_result = 'Rework' then
                   1
                else
                   0
             end
          ) as reworks
     from tdt_production_clean
    group by line_id,
             shift
)
select line_id,
       shift,
       round(
          fails * 100.0 /(pass + fails + reworks),
          1
       ) as fail_rate,
       round(
          reworks * 100.0 /(pass + fails + reworks),
          1
       ) as rework_rate
  from base
 group by line_id,
          shift
 order by fail_rate desc;

-- Q2: Most frequent defect types by component type
-- ============================================================
-- FINDING: Solder Bridge is the most widespread defect, appearing
-- across multiple component types and leading in Power Amplifier (8),
-- Horn Antenna (7) and Transceiver Module (7).
-- OPEN QUESTION: Is Solder Bridge concentration driven by process,
-- material quality, or specific operators? Requires operational investigation.
-- ============================================================
select component_type,
       defect_type,
       count(defect_type) as total_defect_type
  from tdt_production_clean
 where defect_type != 'none'
 group by component_type,
          defect_type
 order by total_defect_type desc;
-- Q3: Operators with non-pass rate above 30%
-- ============================================================
-- FINDING: 12 operators exceed 30% non-pass rate. OP104 leads at 75%
-- but with only 4 units — statistically unreliable.
-- High-volume operators with elevated rates are more actionable:
-- review operators with >5 units AND non_pass_rate >30% as priority.
-- NOTE: 'unknown' excluded — represents 15 unidentified records.
-- Dataset is synthetic and small — operator analysis is indicative only.
-- ============================================================
with base as (
   select operator_id,
          sum(
             case
                when inspection_result = 'Pass' then
                   1
                else
                   0
             end
          ) as pass,
          sum(
             case
                when inspection_result = 'Fail' then
                   1
                else
                   0
             end
          ) as fails,
          sum(
             case
                when inspection_result = 'Rework' then
                   1
                else
                   0
             end
          ) as reworks
     from tdt_production_clean
    group by operator_id
),rates as (
   select operator_id,
          pass,
          fails,
          reworks,
          round(
             fails * 100.0 /(pass + fails + reworks),
             1
          ) as fail_rate,
          round(
             reworks * 100.0 /(pass + fails + reworks),
             1
          ) as reworks_rate,
          round(
             (fails + reworks) * 100.0 /(pass + fails + reworks),
             1
          ) as non_pass_rate
     from base
    where operator_id != 'unknown'
)
select *
  from rates
 where non_pass_rate > 30
 order by non_pass_rate desc;

-- ============================================================
-- Q3 refined: Operators with >5 units and non-pass rate >30%
-- ============================================================
-- FINDING: 28 operators exceed 30% non-pass rate with >5 units produced.
-- OP144 is the highest priority — leads in total volume (19 units) AND
-- has 36.8% non-pass rate (6 fails, 1 rework).
-- High volume + high defect rate = maximum quality risk exposure.
-- Recommend immediate review of OP144's assignments and working conditions.
-- ============================================================
with base as (
   select operator_id,
          sum(
             case
                when inspection_result = 'Pass' then
                   1
                else
                   0
             end
          ) as pass,
          sum(
             case
                when inspection_result = 'Fail' then
                   1
                else
                   0
             end
          ) as fails,
          sum(
             case
                when inspection_result = 'Rework' then
                   1
                else
                   0
             end
          ) as reworks
     from tdt_production_clean
    group by operator_id
),rates as (
   select operator_id,
          pass,
          fails,
          reworks,
          round(pass + fails + reworks) as total_units_produced,
          round(
             fails * 100.0 /(pass + fails + reworks),
             1
          ) as fail_rate,
          round(
             reworks * 100.0 /(pass + fails + reworks),
             1
          ) as reworks_rate,
          round(
             (fails + reworks) * 100.0 /(pass + fails + reworks),
             1
          ) as non_pass_rate
     from base
    where operator_id != 'unknown'
)
select *
  from rates
 where non_pass_rate > 30
   and total_units_produced > 5
 order by non_pass_rate desc;
-- Q4: Temporal concentration of defects by quarter
-- ============================================================
-- FINDING: Q2 2023 was the peak defect quarter (35 fail+rework).
-- Despite higher production volume in Q2 2024 (74 vs 70 units),
-- defects dropped to 22 — a 37% reduction year over year.
-- This suggests quality control improvements took effect in 2024.
-- 2024 Q3 (27) and Q1 (26) remain elevated — worth monitoring.
-- ============================================================
select strftime(
   '%Y',
   production_date
) as year,
       case
          when cast(strftime(
             '%m',
             production_date
          ) as integer) between 1 and 3   then
             'Q1'
          when cast(strftime(
             '%m',
             production_date
          ) as integer) between 4 and 6   then
             'Q2'
          when cast(strftime(
             '%m',
             production_date
          ) as integer) between 7 and 9   then
             'Q3'
          when cast(strftime(
             '%m',
             production_date
          ) as integer) between 10 and 12 then
             'Q4'
       end as quarter,
       sum(
          case
             when inspection_result = 'Fail'
                 or inspection_result = 'Rework' then
                1
             else
                0
          end
       ) as total_defects,
       sum(
          case
             when inspection_result = 'Fail'
                 or inspection_result = 'Rework'
                 or inspection_result = 'Pass' then
                1
             else
                0
          end
       ) as total_produced
  from tdt_production_clean
 group by year,
          quarter
 order by total_defects desc;
-- ============================================================
-- BLOCK C SUMMARY — Quality Risk & Defect Patterns
-- ============================================================
-- 1. Line A Morning is the highest risk combination (26.0% fail rate).
--    Morning shift is consistently problematic across all three lines.
-- 2. Solder Bridge is the most widespread defect type, leading in
--    Power Amplifier, Horn Antenna and Transceiver Module.
-- 3. OP144 — highest volume operator — also has 36.8% non-pass rate.
--    High volume + high defect rate = maximum quality risk exposure.
-- 4. Q2 2023 was peak defect quarter (35). Q2 2024 dropped to 22
--    despite higher volume — quality improvements evident in 2024.
-- ============================================================