# Production Quality & Defect Analysis
## Torrens Defence Technologies — 2023–2024
---
<img width="2550" height="1409" alt="Screenshot 2026-03-27 at 8 00 29 pm" src="https://github.com/user-attachments/assets/8bb2bacd-4760-4859-965e-be4689bb40ce" />

---

## Business Problem

Torrens Defence Technologies (TDT) needed to understand production 
performance across 2023–2024 to support a board-level review. 
Leadership required clarity on output volumes, cost profile, and 
where quality issues were concentrated across lines, shifts, and operators.

---

## Dataset

| Attribute | Detail |
|---|---|
| Source | Synthetic dataset — patterns are indicative only |
| Raw rows | 500 |
| Clean rows | 475 (after deduplication) |
| Period | 2023–2024 |
| Tool | DBeaver + SQLite + Tableau Public |

**Key cleaning decisions:**
- 25 duplicate unit_ids removed — kept MAX(rowid)
- 8 date formats standardised to ISO YYYY-MM-DD
- Negative unit_cost_aud retained — represent credits and returns
- operator_id blanks converted to 'unknown' (15 records)
- inspection_result and categorical columns normalised

---
## Visualisation

Interactive Tableau dashboard built from this SQL analysis.
Answers the central business question:

> **"Can TDT scale production in 2025 without compromising quality?"**

| View | Question |
|---|---|
| Production Trend 2023-2024 | Did the business grow efficiently? |
| Defect Heatmap | Where are defects concentrated? |
| Operator Risk | Who represents the highest risk? |
| Top Defects — High Risk Components | What is failing and where? |
| Quality Year over Year | Is quality improving? |

🔗 [View Interactive Dashboard on Tableau Public](https://public.tableau.com/app/profile/camilo.barrera3824/viz/TDTProductionQuality23-24/Dashboard1?publish=yes)
---

## Analysis Structure

| File | Block | Focus |
|---|---|---|
| `01_tdt_audit.sql` | Audit | Data quality assessment |
| `02_tdt_cleaning.sql` | Cleaning | Standardisation and deduplication |
| `03_eda_tdt_business_context.sql` | Block A | Volume, cost, client distribution |
| `04_eda_tdt_operator_line.sql` | Block B | Operator, line and shift behaviour |
| `05_eda_tdt_quality_risk.sql` | Block C | Defect rates, patterns and risk |

---

## Key Findings

### Production & Cost
- Volume increased in 2024 (+35 units) while total production cost 
  dropped ~$38,500 — cost per unit improved across all clients and 
  most product lines.
- TDT shows no client concentration risk — Export leads at 38% but 
  all three clients (Defence, Export, Mining) are balanced.
- Q2 is the peak production quarter in both years. A sharp drop in 
  Q3 2023 (volume and cost) warrants operational investigation.

### Lines & Shifts
- Production volume is evenly distributed across Line A, B, C and 
  all three shifts — no workload concentration detected.
- This means any quality concentration identified below cannot be 
  attributed to volume imbalance.

### Quality Risk
- **Line A Morning** is the highest risk combination — 26.0% fail rate, 
  with RF Assembly Morning reaching 50% in isolation.
- **Solder Bridge** is the most widespread defect type, concentrated in 
  Power Amplifier, Horn Antenna and Transceiver Module.
- **OP144** — the highest volume operator (19 units) — carries a 36.8% 
  non-pass rate. High volume combined with elevated defect rate 
  represents the greatest quality risk exposure in the dataset.
- Quality improved year over year: Q2 2023 had 35 fail/rework units 
  vs 22 in Q2 2024 despite higher production volume.

---

## Recommendations

1. **Audit Line A Morning shift** — investigate RF Assembly process, 
   tooling, and operator assignments. Fail rate is disproportionate 
   given balanced workload across lines and shifts.

2. **Review OP144 immediately** — highest volume operator with 36.8% 
   non-pass rate. Determine whether the issue is training, tooling, 
   or working conditions.

3. **Investigate Solder Bridge defects** — most frequent and widespread 
   defect type. Determine whether root cause is process, material 
   quality, or operator technique.

---

## Limitations

- Dataset is synthetic — findings are illustrative, not statistically 
  conclusive.
- 500 rows (475 clean) is a small sample for robust inference.
- operator_id has 15 unknown records — operator analysis is approximate.
- unit_cost_aud represents production cost, not sale price. Negative 
  values (credits/returns) affect aggregate cost calculations.

---

## Author
Camilo B. Martinez — Junior Data Analyst  
Adelaide, SA, Australia  

🔗 [Repo link](https://github.com/Camilo-analytics/tdt-production-quality-sql)
