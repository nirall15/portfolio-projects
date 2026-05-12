-- ============================================================
-- HYPERSCALER CAPEX ANALYSIS — DATABASE SETUP
-- Author: Niral Rai
-- Date: April 2026
-- Source: Company 10-Q filings (SEC EDGAR) and earnings press releases
-- ============================================================

-- Use the database you created earlier
USE hyperscaler_analysis;

-- Drop existing objects if rerunning (safe to include)
DROP VIEW IF EXISTS v_summary_stats;
DROP VIEW IF EXISTS v_capex_growth;
DROP VIEW IF EXISTS v_capex_to_revenue;
DROP TABLE IF EXISTS legal_exposure;
DROP TABLE IF EXISTS financials;

-- ============================================================
-- TABLE 1: financials
-- Quarterly capex and revenue for each hyperscaler
-- ============================================================
CREATE TABLE financials (
  company          VARCHAR(10)    NOT NULL,
  quarter          VARCHAR(10)    NOT NULL,
  calendar_year    INT            NOT NULL,
  calendar_q       INT            NOT NULL,
  capex_billions   DECIMAL(6,1)   NOT NULL,
  revenue_billions DECIMAL(7,1)   NOT NULL,
  PRIMARY KEY (company, quarter),
  INDEX idx_company (company),
  INDEX idx_year_q  (calendar_year, calendar_q)
);

INSERT INTO financials 
  (company, quarter, calendar_year, calendar_q, capex_billions, revenue_billions) 
VALUES
  ('MSFT',  '2024Q1', 2024, 1, 14.0, 61.9),
  ('MSFT',  '2024Q2', 2024, 2, 19.0, 64.7),
  ('MSFT',  '2024Q3', 2024, 3, 20.0, 65.6),
  ('MSFT',  '2024Q4', 2024, 4, 22.6, 69.6),
  ('MSFT',  '2025Q1', 2025, 1, 21.4, 70.1),
  ('MSFT',  '2025Q2', 2025, 2, 24.2, 76.4),
  ('MSFT',  '2025Q3', 2025, 3, 34.9, 77.7),
  ('MSFT',  '2025Q4', 2025, 4, 37.5, 81.3),
  ('GOOGL', '2024Q1', 2024, 1, 12.0, 80.5),
  ('GOOGL', '2024Q2', 2024, 2, 13.0, 84.7),
  ('GOOGL', '2024Q3', 2024, 3, 13.1, 88.3),
  ('GOOGL', '2024Q4', 2024, 4, 14.3, 96.5),
  ('GOOGL', '2025Q1', 2025, 1, 17.2, 90.2),
  ('GOOGL', '2025Q2', 2025, 2, 22.4, 96.4),
  ('GOOGL', '2025Q3', 2025, 3, 24.0, 102.3),
  ('GOOGL', '2025Q4', 2025, 4, 27.9, 110.0),
  ('META',  '2024Q1', 2024, 1,  6.7, 36.5),
  ('META',  '2024Q2', 2024, 2,  8.5, 39.1),
  ('META',  '2024Q3', 2024, 3,  9.2, 40.6),
  ('META',  '2024Q4', 2024, 4, 14.8, 48.4),
  ('META',  '2025Q1', 2025, 1, 13.7, 42.3),
  ('META',  '2025Q2', 2025, 2, 17.0, 47.5),
  ('META',  '2025Q3', 2025, 3, 19.4, 51.2),
  ('META',  '2025Q4', 2025, 4, 22.1, 58.0),
  ('AMZN',  '2024Q1', 2024, 1, 14.9, 143.3),
  ('AMZN',  '2024Q2', 2024, 2, 17.6, 148.0),
  ('AMZN',  '2024Q3', 2024, 3, 22.6, 158.9),
  ('AMZN',  '2024Q4', 2024, 4, 27.8, 187.8),
  ('AMZN',  '2025Q1', 2025, 1, 24.3, 155.7),
  ('AMZN',  '2025Q2', 2025, 2, 32.2, 167.7),
  ('AMZN',  '2025Q3', 2025, 3, 34.2, 180.2),
  ('AMZN',  '2025Q4', 2025, 4, 31.4, 195.0);

-- ============================================================
-- TABLE 2: legal_exposure
-- Qualitative risk tracker (populated in next step)
-- ============================================================
CREATE TABLE legal_exposure (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  company          VARCHAR(10) NOT NULL,
  risk_category    VARCHAR(50) NOT NULL,
  matter_description TEXT,
  status           VARCHAR(50),
  potential_impact VARCHAR(20),
  source           VARCHAR(200),
  INDEX idx_company (company),
  INDEX idx_category (risk_category)
);

-- Seed a few placeholder rows — we'll populate fully in the next step
INSERT INTO legal_exposure 
  (company, risk_category, matter_description, status, potential_impact, source)
VALUES
  ('MSFT',  'Antitrust', 'FTC review of Microsoft-OpenAI relationship', 'Ongoing',     'Medium', 'TBD'),
  ('GOOGL', 'Antitrust', 'DOJ search monopoly case — remedies phase',   'Ongoing',     'High',   'TBD'),
  ('AMZN',  'Antitrust', 'FTC v. Amazon (e-commerce monopolization)',   'Ongoing',     'High',   'TBD'),
  ('META',  'Antitrust', 'FTC v. Meta (Instagram / WhatsApp divest.)',  'Trial phase', 'High',   'TBD');

-- ============================================================
-- VIEW 1: Capex as % of revenue (most important ratio)
-- ============================================================
CREATE VIEW v_capex_to_revenue AS
SELECT 
  company,
  quarter,
  calendar_year,
  calendar_q,
  capex_billions,
  revenue_billions,
  ROUND(capex_billions / revenue_billions * 100, 1) AS capex_pct_of_revenue
FROM financials
ORDER BY company, calendar_year, calendar_q;

-- ============================================================
-- VIEW 2: QoQ and YoY capex growth
-- Uses window functions — demonstrates advanced SQL skill
-- ============================================================
CREATE VIEW v_capex_growth AS
SELECT 
  company,
  quarter,
  calendar_year,
  calendar_q,
  capex_billions,
  LAG(capex_billions, 1) OVER (PARTITION BY company ORDER BY calendar_year, calendar_q) 
    AS prev_q_capex,
  LAG(capex_billions, 4) OVER (PARTITION BY company ORDER BY calendar_year, calendar_q) 
    AS prev_y_capex,
  ROUND(
    (capex_billions - LAG(capex_billions, 1) OVER (PARTITION BY company ORDER BY calendar_year, calendar_q)) 
    / LAG(capex_billions, 1) OVER (PARTITION BY company ORDER BY calendar_year, calendar_q) * 100, 1
  ) AS qoq_growth_pct,
  ROUND(
    (capex_billions - LAG(capex_billions, 4) OVER (PARTITION BY company ORDER BY calendar_year, calendar_q)) 
    / LAG(capex_billions, 4) OVER (PARTITION BY company ORDER BY calendar_year, calendar_q) * 100, 1
  ) AS yoy_growth_pct
FROM financials;

-- ============================================================
-- VIEW 3: Company-level summary stats
-- ============================================================
CREATE VIEW v_summary_stats AS
SELECT 
  company,
  COUNT(*)                                      AS quarters_count,
  ROUND(SUM(capex_billions), 1)                 AS total_2y_capex_b,
  ROUND(SUM(revenue_billions), 1)               AS total_2y_revenue_b,
  ROUND(AVG(capex_billions), 1)                 AS avg_quarterly_capex_b,
  ROUND(AVG(capex_billions / revenue_billions) * 100, 1) AS avg_capex_pct_rev,
  ROUND(MIN(capex_billions), 1)                 AS min_quarterly_capex_b,
  ROUND(MAX(capex_billions), 1)                 AS max_quarterly_capex_b
FROM financials
GROUP BY company
ORDER BY total_2y_capex_b DESC;

-- Query 1: Who spent the most over the two years? 
SELECT * FROM v_summary_stats;

-- Query 2: Capex-to-revenue ratio — who's stretching most?
SELECT company, quarter, capex_billions, revenue_billions, capex_pct_of_revenue
FROM v_capex_to_revenue
WHERE quarter IN ('2024Q1', '2025Q4')
ORDER BY company, quarter;

-- Query 3: QoQ and YoY growth view
SELECT company, quarter, capex_billions, qoq_growth_pct, yoy_growth_pct
FROM v_capex_growth
WHERE calendar_year = 2025
ORDER BY company, calendar_q;

-- Query 4: The AI infrastructure totals
SELECT 
  calendar_year,
  ROUND(SUM(capex_billions), 1) AS total_capex_b,
  ROUND(SUM(revenue_billions), 1) AS total_revenue_b
FROM financials
GROUP BY calendar_year
ORDER BY calendar_year;

-- Query 5: Rank quarters by capex across all companies
SELECT 
  quarter,
  company,
  capex_billions,
  RANK() OVER (PARTITION BY quarter ORDER BY capex_billions DESC) AS rank_in_quarter
FROM financials
ORDER BY calendar_year, calendar_q, rank_in_quarter;
