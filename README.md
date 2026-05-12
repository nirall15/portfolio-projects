# Project Portfolio
A collection of end-to-end data analytics projects using real public datasets. Each project covers data ingestion, cleaning, SQL analysis, and Tableau visualization.

---

## Table of Contents

1. [Hospital Readmission Risk Analysis](./hospital_readmission_analysis.sql)
2. [Hyperscaler AI Infrastructure & CapEx Analysis](#2-hyperscaler-ai-infrastructure--capex-analysis)
3. [Public Company Earnings & Anomaly Tracker](#2-public-company-earnings--anomaly-tracker)

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

---
## 2. Hyperscaler AI Infrastructure & CapEx Analysis

### Overview
Analyzed capital expenditure (CapEx) trends and AI infrastructure spending across the four
major hyperscalers — Microsoft, Google, Amazon, and Meta — over 8 quarters (2024–2025).
Tracks how aggressively each company is investing in AI infrastructure relative to their
revenue, and identifies which is "stretching" the most financially.

Also includes a qualitative legal risk tracker monitoring active antitrust cases against
each company (DOJ, FTC) and their potential financial impact.

### Data Source
- **Dataset:** Manually curated from company 10-Q SEC filings and earnings press releases
- **Companies:** MSFT, GOOGL, AMZN, META
- **Period:** Q1 2024 – Q4 2025 (8 quarters per company, 32 rows)

### Tools
MySQL (MySQL Workbench), Tableau Public

### SQL Skills Demonstrated
- Multi-table schema design with primary keys and indexes
- `LAG()` window function for QoQ and YoY growth calculations
- `PARTITION BY` for per-company growth tracking
- SQL Views (`CREATE VIEW`) to modularize reusable logic
- `RANK() OVER` for cross-company quarterly ranking
- Aggregate functions: `SUM`, `AVG`, `MIN`, `MAX`, `ROUND`
- Derived metrics: CapEx as % of revenue, growth rates

### Queries & Views

| Object | Type | Description |
|--------|------|-------------|
| `v_capex_to_revenue` | View | CapEx as % of revenue per quarter per company |
| `v_capex_growth` | View | QoQ and YoY CapEx growth using LAG() |
| `v_summary_stats` | View | 2-year totals, averages, min/max per company |
| Query 1 | Analysis | Who spent the most over 2 years? |
| Query 2 | Analysis | CapEx-to-revenue ratio — who is stretching most? |
| Query 3 | Analysis | QoQ and YoY growth in 2025 |
| Query 4 | Analysis | Total AI infrastructure spend by year across all 4 |
| Query 5 | Analysis | Rank companies by CapEx within each quarter |

### Key Findings
- Amazon had the highest total 2-year CapEx across all 4 hyperscalers
- Meta showed the steepest YoY CapEx growth rate in 2025, signaling aggressive AI catch-up spending
- All 4 companies significantly accelerated CapEx from 2024 to 2025, reflecting the AI infrastructure arms race
- Google maintains the highest CapEx-to-revenue ratio among the group, suggesting the greatest relative financial stretch
- All 4 companies face active high-impact antitrust cases (DOJ/FTC) which could materially affect future spending capacity

### Links
- [View SQL](./hyperscaler_analysis.sql)
- [Tableau Dashboard](https://public.tableau.com/views/HyperscalerAIInfrastructureAnalysis/Dashboard1)

---
## 3. Public Company Earnings & Anomaly Tracker

### Overview
Analyzed 2.2M financial records across 6,169 public companies from SEC EDGAR 
Q1 2026 10-Q filings to identify top performers, industry trends, and cash 
burn anomalies.

### Data Source
- **Dataset:** SEC EDGAR Financial Statement Data Sets Q1 2026
- **Source:** [sec.gov](https://www.sec.gov/data-research/sec-markets-data/financial-statement-data-sets)
- **Records:** 2.2M financial records | 6,169 companies | 1 quarter

### Tools
MySQL (MySQL Workbench), Tableau (in progress)

### SQL Skills Demonstrated
- Multi-table JOIN across companies and financials
- Pivot logic using `MAX(CASE WHEN tag = '...' THEN value END)`
- `NULLIF` for divide-by-zero protection in margin calculations
- Anomaly detection using `HAVING` with compound conditions
- Aggregate functions across millions of rows
- Industry-level grouping by SIC code

### Files
- [earnings_anomaly_tracker.sql](./earnings_anomaly_tracker.sql)
