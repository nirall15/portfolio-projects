-- ============================================================
--  PUBLIC COMPANY EARNINGS & ANOMALY TRACKER
--  Data Source: SEC EDGAR Financial Statement Data Sets
--               Q1 2026 (10-Q Filings)
--  Author: Niral Rai
--  Date: 2026
-- ============================================================

-- ============================================================
--  SETUP: Create database and tables
CREATE DATABASE IF NOT EXISTS finance_project;
USE finance_project;

DROP TABLE IF EXISTS financials;
DROP TABLE IF EXISTS companies;

CREATE TABLE companies (
    adsh        VARCHAR(20) PRIMARY KEY,  -- unique filing ID (join key)
    cik         VARCHAR(20),              -- company ID
    name        VARCHAR(100),             -- company name
    sic         VARCHAR(10),              -- industry code
    form        VARCHAR(10),              -- filing type (10-K, 10-Q)
    period      VARCHAR(10),              -- reporting period
    fy          VARCHAR(10),              -- fiscal year
    fp          VARCHAR(10),              -- fiscal period (Q1-Q4, FY)
    filed       VARCHAR(10)               -- date filed with SEC
);

CREATE TABLE financials (
    adsh        VARCHAR(20),              -- join key to companies
    tag         VARCHAR(100),             -- financial metric name
    ddate       VARCHAR(10),              -- period end date
    qtrs        INT,                      -- quarters covered (1=quarterly, 4=annual)
    uom         VARCHAR(20),              -- unit of measure (USD, shares)
    value       DECIMAL(20,2)             -- the actual number
);

SELECT 'Tables created successfully' AS status;


-- ============================================================
-- Load company/submission data
LOAD DATA LOCAL INFILE '/Users/niralrai/Downloads/2026q1/sub.txt'
INTO TABLE companies
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(adsh, cik, name, sic, @countryba, @stprba, @cityba, @zipba, @bas1, @bas2,
 @baph, @countryma, @stprma, @cityma, @zipma, @mas1, @mas2, @countryinc,
 @stprinc, @ein, @former, @changed, @afs, @wksi, @fye, form, period, fy, fp,
 filed, @accepted, @prevrpt, @detail, @instance, @nciks, @aciks);

SELECT CONCAT(COUNT(*), ' companies loaded') AS status FROM companies;

-- Load filtered financial metrics
-- Pre-filtered to: Revenues, NetIncomeLoss, GrossProfit,
--                  OperatingIncomeLoss, EarningsPerShareBasic, Assets
LOAD DATA LOCAL INFILE '/Users/niralrai/Downloads/num_filtered.txt'
INTO TABLE financials
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(adsh, tag, @version, ddate, qtrs, uom, @segments, @coreg, value, @footnote);

SELECT CONCAT(COUNT(*), ' financial records loaded') AS status FROM financials;


-- ============================================================
--  DATA QUALITY CHECK

SELECT 'Running data quality checks...' AS status;

-- Row counts
SELECT COUNT(*) AS total_companies FROM companies;
SELECT COUNT(*) AS total_financial_records FROM financials;

-- Confirm key tags are present and their record counts
SELECT
    tag,
    COUNT(*)                             AS record_count
FROM financials
WHERE tag IN ('Revenues', 'NetIncomeLoss', 'GrossProfit',
              'OperatingIncomeLoss', 'EarningsPerShareBasic', 'Assets')
GROUP BY tag
ORDER BY record_count DESC;

-- Check filing types available
SELECT form, COUNT(*) AS count
FROM companies
GROUP BY form
ORDER BY count DESC;

-- Spot check a known company
SELECT c.name, f.tag, f.value, f.ddate
FROM companies c
JOIN financials f ON c.adsh = f.adsh
WHERE c.name LIKE '%APPLE%'
  AND f.qtrs = 1
LIMIT 10;


-- ============================================================
--  QUERY 1: Top Companies by Revenue
--  Multi-metric view: revenue, net income, gross profit,
--  and operating income for the most recent quarter

SELECT 'Query 1: Top companies by revenue' AS status;

SELECT
    c.name,
    c.fp                                           AS fiscal_period,
    c.fy                                           AS fiscal_year,
    MAX(CASE WHEN f.tag = 'Revenues'
        THEN f.value END)                          AS revenue,
    MAX(CASE WHEN f.tag = 'NetIncomeLoss'
        THEN f.value END)                          AS net_income,
    MAX(CASE WHEN f.tag = 'GrossProfit'
        THEN f.value END)                          AS gross_profit,
    MAX(CASE WHEN f.tag = 'OperatingIncomeLoss'
        THEN f.value END)                          AS operating_income
FROM companies c
JOIN financials f ON c.adsh = f.adsh
WHERE f.tag IN ('Revenues','NetIncomeLoss','GrossProfit','OperatingIncomeLoss')
  AND f.qtrs = 1
  AND c.form = '10-Q'
  AND f.value IS NOT NULL
GROUP BY c.name, c.fp, c.fy
HAVING revenue IS NOT NULL
ORDER BY revenue DESC
LIMIT 20;


-- ============================================================
--  QUERY 2: Net Profit Margin by Company
--  Net income as % of revenue — who is most efficient?
--  NULLIF prevents divide-by-zero errors

SELECT 'Query 2: Net profit margin ranking' AS status;

SELECT
    c.name,
    c.fy                                           AS fiscal_year,
    c.fp                                           AS fiscal_period,
    MAX(CASE WHEN f.tag = 'Revenues'
        THEN f.value END)                          AS revenue,
    MAX(CASE WHEN f.tag = 'NetIncomeLoss'
        THEN f.value END)                          AS net_income,
    ROUND(
        MAX(CASE WHEN f.tag = 'NetIncomeLoss' THEN f.value END) * 100.0 /
        NULLIF(MAX(CASE WHEN f.tag = 'Revenues' THEN f.value END), 0)
    , 2)                                           AS net_margin_pct
FROM companies c
JOIN financials f ON c.adsh = f.adsh
WHERE f.tag IN ('Revenues', 'NetIncomeLoss')
  AND f.qtrs = 1
  AND c.form = '10-Q'
GROUP BY c.name, c.fy, c.fp
HAVING revenue > 1000000
   AND net_income IS NOT NULL
ORDER BY net_margin_pct DESC
LIMIT 20;


-- ============================================================
--  QUERY 3: EPS Ranking
--  Earnings per share — which companies return the most
--  value per share to investors?

SELECT 'Query 3: EPS ranking' AS status;

SELECT
    c.name,
    c.fy                                           AS fiscal_year,
    c.fp                                           AS fiscal_period,
    f.value                                        AS eps,
    f.ddate                                        AS period_end
FROM companies c
JOIN financials f ON c.adsh = f.adsh
WHERE f.tag = 'EarningsPerShareBasic'
  AND f.qtrs = 1
  AND c.form = '10-Q'
  AND f.value IS NOT NULL
ORDER BY f.value DESC
LIMIT 20;


-- ============================================================
--  QUERY 4: Industry-Level Revenue Analysis
--  Grouped by SIC industry code — which sectors generate
--  the most revenue and profit on average?

SELECT 'Query 4: Revenue and profit by industry (SIC code)' AS status;

SELECT
    c.sic                                          AS industry_code,
    COUNT(DISTINCT c.name)                         AS company_count,
    ROUND(AVG(CASE WHEN f.tag = 'Revenues'
        THEN f.value END), 2)                      AS avg_revenue,
    ROUND(AVG(CASE WHEN f.tag = 'NetIncomeLoss'
        THEN f.value END), 2)                      AS avg_net_income,
    ROUND(AVG(CASE WHEN f.tag = 'GrossProfit'
        THEN f.value END), 2)                      AS avg_gross_profit,
    ROUND(
        AVG(CASE WHEN f.tag = 'NetIncomeLoss' THEN f.value END) * 100.0 /
        NULLIF(AVG(CASE WHEN f.tag = 'Revenues' THEN f.value END), 0)
    , 2)                                           AS avg_margin_pct
FROM companies c
JOIN financials f ON c.adsh = f.adsh
WHERE f.tag IN ('Revenues', 'NetIncomeLoss', 'GrossProfit')
  AND f.qtrs = 1
  AND c.form = '10-Q'
  AND f.value IS NOT NULL
GROUP BY c.sic
HAVING avg_revenue IS NOT NULL
   AND company_count >= 5
ORDER BY avg_revenue DESC
LIMIT 20;


-- ============================================================
--  QUERY 5: Anomaly Detection — Cash Burn Signals
--  Companies with positive revenue but negative net income
--  These companies are spending more than they earn
--  Filtered to companies with >$10M revenue (excludes tiny firms)

SELECT 'Query 5: Anomaly detection - profitable revenue, negative income' AS status;

SELECT
    c.name,
    c.fy                                           AS fiscal_year,
    c.fp                                           AS fiscal_period,
    c.sic                                          AS industry_code,
    MAX(CASE WHEN f.tag = 'Revenues'
        THEN f.value END)                          AS revenue,
    MAX(CASE WHEN f.tag = 'NetIncomeLoss'
        THEN f.value END)                          AS net_income,
    ROUND(
        MAX(CASE WHEN f.tag = 'NetIncomeLoss' THEN f.value END) * 100.0 /
        NULLIF(MAX(CASE WHEN f.tag = 'Revenues' THEN f.value END), 0)
    , 2)                                           AS net_margin_pct
FROM companies c
JOIN financials f ON c.adsh = f.adsh
WHERE f.tag IN ('Revenues', 'NetIncomeLoss')
  AND f.qtrs = 1
  AND c.form = '10-Q'
GROUP BY c.name, c.fy, c.fp, c.sic
HAVING revenue > 10000000
   AND net_income < 0
ORDER BY net_income ASC
LIMIT 20;


-- ============================================================
--  QUERY 6: Gross Margin Ranking
--  Gross profit as % of revenue — operational efficiency
--  High gross margin = strong pricing power or low COGS

SELECT 'Query 6: Gross margin ranking' AS status;

SELECT
    c.name,
    c.fy                                           AS fiscal_year,
    c.fp                                           AS fiscal_period,
    MAX(CASE WHEN f.tag = 'Revenues'
        THEN f.value END)                          AS revenue,
    MAX(CASE WHEN f.tag = 'GrossProfit'
        THEN f.value END)                          AS gross_profit,
    ROUND(
        MAX(CASE WHEN f.tag = 'GrossProfit' THEN f.value END) * 100.0 /
        NULLIF(MAX(CASE WHEN f.tag = 'Revenues' THEN f.value END), 0)
    , 2)                                           AS gross_margin_pct
FROM companies c
JOIN financials f ON c.adsh = f.adsh
WHERE f.tag IN ('Revenues', 'GrossProfit')
  AND f.qtrs = 1
  AND c.form = '10-Q'
GROUP BY c.name, c.fy, c.fp
HAVING revenue > 1000000
   AND gross_profit IS NOT NULL
ORDER BY gross_margin_pct DESC
LIMIT 20;


-- ============================================================
--  QUERY 7: Summary Dashboard Metrics
--  Single-row KPIs for Tableau summary cards

SELECT 'Query 7: Summary dashboard metrics' AS status;

SELECT
    COUNT(DISTINCT c.name)                         AS total_companies,
    COUNT(DISTINCT c.sic)                          AS total_industries,
    ROUND(AVG(CASE WHEN f.tag = 'Revenues'
        THEN f.value END), 2)                      AS avg_revenue,
    ROUND(AVG(CASE WHEN f.tag = 'NetIncomeLoss'
        THEN f.value END), 2)                      AS avg_net_income,
    ROUND(AVG(CASE WHEN f.tag = 'EarningsPerShareBasic'
        THEN f.value END), 2)                      AS avg_eps,
    SUM(CASE WHEN f.tag = 'NetIncomeLoss'
        AND f.value < 0 THEN 1 ELSE 0 END)         AS companies_reporting_losses
FROM companies c
JOIN financials f ON c.adsh = f.adsh
WHERE f.qtrs = 1
  AND c.form = '10-Q';

SELECT 'Analysis complete! Ready for Tableau.' AS status;