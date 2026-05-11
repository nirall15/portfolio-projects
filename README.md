# SQL & Tableau Portfolio
A collection of end-to-end data analytics projects using real public datasets. Each project covers data ingestion, cleaning, SQL analysis, and Tableau visualization.

---

## Table of Contents

1. [Hospital Readmission Risk Analysis](./hospital_readmission_analysis.sql)

---

## 1. Hospital Readmission Risk Analysis

### Overview
Analyzed 250,000 hospital records from the CMS FY 2026 Hospital Readmissions Reduction Program (HRRP) to identify readmission risk patterns across U.S. hospitals, conditions, and states.

The HRRP is a Medicare program that financially penalizes hospitals with excess 30-day readmission rates. An excess readmission ratio above 1.0 means a hospital is performing worse than the national average for that condition.

### Data Source
- **Dataset:** CMS FY 2026 Hospital Readmissions Reduction Program
- **Source:** [data.cms.gov](https://data.cms.gov/provider-data/dataset/9n3s-kdb3)
- **Records:** 250,000 rows | ~3,000 U.S. hospitals | 6 conditions
- **Performance Period:** July 1, 2021 – June 30, 2024

### Tools
MySQL (MySQL Workbench), Tableau (in progress)

### SQL Skills Demonstrated
- Database design and table creation with appropriate data types
- Handling messy real-world data (N/A, Too Few to Report values)
- `CASE` statements for custom performance tier segmentation
- Aggregate functions: `COUNT`, `AVG`, `MIN`, `MAX`, `SUM`
- Window functions: `SUM() OVER ()` for percentage-of-total calculations
- `GROUP BY`, `HAVING`, `ORDER BY`
- Multi-condition filtering with `WHERE`
- Data quality checks before analysis

### Queries

| Query | Description |
|-------|-------------|
| Data Quality Check | Null counts, value distribution, row verification |
| Query 1 | State-level readmission overview — avg excess ratio ranked by state |
| Query 2 | Readmission rate by condition — which diagnoses are highest risk |
| Query 3 | Performance tier distribution — hospitals bucketed into 4 risk tiers |
| Query 4 | Worst performing hospitals — top 20 by excess readmission ratio |
| Query 5 | Best performing hospitals — consistently below national avg across 3+ conditions |
| Query 6 | State × condition heatmap — risk tier by geography and diagnosis |
| Query 7 | Predicted vs expected rate gap — how far off hospitals are by condition |
| Query 8 | Summary KPI metrics — single-row numbers for Tableau dashboard cards |

### Key Findings
- Hospitals with excess readmission ratios above 1.10 face the steepest CMS payment penalties
- Heart failure and COPD show the highest average excess readmission ratios nationally
- Significant state-level variation exists, suggesting regional differences in post-discharge care quality
- A subset of hospitals consistently perform below the national average across 3+ conditions, signaling best-practice care coordination

### Files
- [hospital_readmission_analysis.sql](./hospital_readmission_analysis.sql)
- [Tableau Dashboard](https://public.tableau.com/views/HospitalReadmissionRiskAnalysis_17784699066340/Dashboard1)
