-- ============================================================
-- 03_eda_tdt_business_context.sql
-- Project: Production Quality & Defect Analysis
-- Torrens Defence Technologies 2023–2024
-- ============================================================
-- BUSINESS BRIEF (Sarah Chen, Production Manager):
-- "How much did we produce, for whom, and at what cost?"
--
-- ANALYST QUESTIONS:
-- Q1: What was total production cost (units + cost) by year?
-- Q2: Which clients drove the most volume — and is there concentration risk?
-- Q3: What was the average cost per unit by product line?
--
-- DECISION: Year-over-year breakdown preferred over global aggregates
-- REASON: Global totals can mask declining trends across periods
--
-- NOTE ON unit_cost_aud:
-- This column represents production cost per unit, NOT sale price.
-- Negative values represent credits and returns — reported separately
-- to avoid distorting total production cost figures.
-- Interpret combined totals with caution.
-- ============================================================


-- ============================================================
-- Q1: What was total production cost and volume by year?
-- ============================================================
-- FINDING: Production volume increased in 2024 (+35 units) but total
-- cost dropped ~$38,500. Cost per unit fell significantly year over year,
-- suggesting improved production efficiency across the board.
-- ============================================================

select strftime(
   '%Y',
   production_date
) as year,
       count(unit_id) as total_units,
       round(
          sum(unit_cost_aud),
          2
       ) as total_unit_cost
  from tdt_production_clean
 group by year
 order by year desc;


-- ============================================================
-- Q2: Which clients drove the most volume — and is there concentration risk?
-- ============================================================
-- FINDING: Export leads volume in both years (~38%) but all three clients
-- are relatively balanced (Defence 32%, Mining 28-29%).
-- No single client exceeds 40% — TDT shows no significant concentration risk.
-- All three clients reduced cost per unit in 2024 despite increased volume,
-- confirming the efficiency trend observed in Q1.
-- ============================================================

with base as (
   select strftime(
      '%Y',
      production_date
   ) as year,
          round(
             sum(unit_cost_aud),
             2
          ) as total_cost,
          count(unit_id) as total_units,
          client
     from tdt_production_clean
    group by year,
             client
)
select year,
       client,
       total_cost,
       total_units,
       round(
          total_units * 100.0 / sum(total_units)
                                over(partition by year),
          1
       ) as pct_total,
       lag(total_cost)
       over(partition by client
            order by year
       ) as prev_year_cost,
       round(
          (total_cost - lag(total_cost)
                        over(partition by client
                             order by year
          )) / lag(total_cost)
               over(partition by client
                    order by year
          ) * 100,
          1
       ) as cost_change_pct,
       round(
          total_cost / total_units,
          2
       ) as cost_per_unit
  from base
 order by client,
          year;


-- ============================================================
-- Q3: What was the average cost per unit by product line?
-- ============================================================
-- FINDING: 2024 saw cost per unit decrease across most product lines
-- and clients — a strong efficiency signal. One exception:
-- Antenna System for Mining increased in cost per unit in 2024.
-- Lower unit costs provide margin opportunity without impacting client pricing.
-- ============================================================
with base as (
   select strftime(
      '%Y',
      production_date
   ) as year,
          round(
             sum(unit_cost_aud),
             2
          ) as total_cost,
          count(unit_id) as total_units,
          client,
          product_line
     from tdt_production_clean
    group by year,
             client,
             product_line
),base_2 as (
   select year,
          client,
          total_cost,
          total_units,
          product_line,
          round(
             total_units * 100.0 / sum(total_units)
                                   over(partition by year),
             1
          ) as pct_total,
          lag(total_cost)
          over(partition by client,
                            product_line
               order by year
          ) as prev_year_cost,
          round(
             (total_cost - lag(total_cost)
                           over(partition by client,
                                             product_line
                                order by year
             )) / lag(total_cost)
                  over(partition by client,
                                    product_line
                       order by year
             ) * 100,
             1
          ) as cost_change_pct,
          round(
             total_cost / total_units,
             2
          ) as cost_per_unit,
          round(
             total_cost / total_units,
             2
          ) - lag(round(
             total_cost / total_units,
             2
          ))
              over(partition by client,
                                product_line
                   order by year
          ) as cpu_change
     from base
)
select year,
       client,
       total_cost,
       total_units,
       product_line,
       pct_total,
       prev_year_cost,
       cost_change_pct,
       cost_per_unit,
       case
          when cpu_change > 0 then
             'cost increased'
          when cpu_change < 0 then
             'cost decreased'
          else
             'no prior year data'
       end as cost_per_unit_state
  from base_2
 order by client,
          product_line,
          year;
-- ============================================================
-- Q4: Are there temporal trends in volume or cost?
-- ============================================================
-- FINDING: 2023 shows a strong drop in both volume and cost from Q2 to Q3
-- (70 units / $63,647 → 51 units / $19,628). This is the sharpest quarterly
-- decline in the dataset and warrants investigation with Sarah —
-- possible causes include line stoppage, supply issues, or seasonal slowdown.
-- 2024 shows a more stable pattern with Q2 as the peak quarter in both years.
-- OPEN QUESTION: What caused the Q3 2023 production drop?
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
       count(unit_id) as total_volume,
       round(
          sum(unit_cost_aud),
          2
       ) as total_cost
  from tdt_production_clean
 group by year,
          quarter
 order by year,
          quarter;

-- ============================================================
-- BLOCK A SUMMARY — Business Context
-- ============================================================
-- 1. Production volume increased in 2024 (+35 units) but total cost
--    dropped ~$38,500 — cost per unit improved across all clients.
-- 2. No significant client concentration risk — Export leads at 38%
--    but all three clients are balanced.
-- 3. Cost per unit dropped in almost all product line / client combos
--    in 2024. Exception: Antenna System for Mining increased.
-- 4. Q2 is peak production quarter in both years. Sharp drop in
--    Q3 2023 (volume + cost) warrants operational investigation.
-- ============================================================