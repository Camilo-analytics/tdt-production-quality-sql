-- ============================================================
-- 04_eda_tdt_operator_line.sql
-- Project: Production Quality & Defect Analysis
-- Torrens Defence Technologies 2023–2024
-- ============================================================
-- BUSINESS BRIEF (Sarah Chen, Production Manager):
-- "I need to understand how our production lines and operators
-- are performing — where is volume concentrated and are there
-- any behavioral patterns worth investigating?"
--
-- ANALYST QUESTIONS:
-- Q1: Which operators produced the most units?
-- Q2: Are there volume differences between Line A, B, and C?
-- Q3: Which shifts concentrate the most production?
--
-- NOTE ON operator_id:
-- 15 records have operator_id = 'unknown' due to blank values in raw data.
-- Operator-level analysis is indicative only.
-- ============================================================
-- Q1: Which operators produced the most units? (Top 5)
-- ============================================================
-- FINDING: OP144 leads with 19 units — roughly double the expected
-- average of ~9 units per operator across 52 operators.
-- 'unknown' appears in position 4 (14 units) — represents 15 records
-- with no operator identified. See header note on operator_id limitation.
-- ============================================================
select 
operator_id as operator,
count(unit_id)as total_units
from tdt_production_clean
group by operator
order by total_units  desc
limit 5;

-- Q2: Are there volume differences between Line A, B, and C?
-- ============================================================
-- FINDING: Production is evenly distributed across all three lines.
-- Line B leads marginally (167 units) followed by Line C (165) and
-- Line A (143). No single line dominates — workload appears balanced.
-- ============================================================
select 
line_id as line,
count(unit_id)as total_units
from tdt_production_clean
group by line
order by total_units  desc;
-- Q3: Which shifts concentrate the most production?
-- ============================================================
-- FINDING: Production is evenly distributed across all three shifts.
-- Night leads marginally (161 units) followed by Morning (160) and
-- Afternoon (154). No shift dominates — TDT operates consistently
-- across the full 24-hour production cycle.
-- ============================================================
select 
shift,
count(unit_id)as total_units
from tdt_production_clean
group by shift
order by total_units  desc;
-- ============================================================
-- BLOCK B SUMMARY — Operator & Line Behavior
-- ============================================================
-- 1. OP144 leads in volume (19 units) — roughly double the expected
--    average across 52 operators.
-- 2. Production is evenly distributed across Line A, B, and C.
--    No single line dominates workload.
-- 3. All three shifts operate at comparable volume levels.
--    No shift concentration detected.
-- NOTE: Balanced volume across lines and shifts means any quality
-- concentration found in Block C cannot be attributed to workload.
-- ============================================================
