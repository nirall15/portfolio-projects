-- ============================================================
--  HOSPITAL READMISSION RISK ANALYSIS
--  Data Source: CMS Hospital Readmissions Reduction Program
--  Author: Niral Rai
--  Date: May 2026
-- ============================================================

--  SETUP: Create database and table
CREATE DATABASE IF NOT EXISTS readmission_project;
USE readmission_project;

DROP TABLE IF EXISTS hospital_readmissions;

CREATE TABLE hospital_readmissions (
    hospital_name        VARCHAR(100),
    facility_id          VARCHAR(10),
    state                CHAR(2),
    measure_name         VARCHAR(100),
    num_discharges       VARCHAR(20),
    footnote             VARCHAR(10),
    excess_readmit_ratio DECIMAL(8,4),
    predicted_rate       DECIMAL(8,4),
    expected_rate        DECIMAL(8,4),
    num_readmissions     VARCHAR(20),
    start_date           DATE,
    end_date             DATE
);
 
SELECT 'Table created successfully' AS status;

--  LOAD DATA
LOAD DATA LOCAL INFILE '/Users/niralrai/Downloads/FY_2026_Hospital_Readmissions_Reduction_Program_Hospital.csv'
INTO TABLE hospital_readmissions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(hospital_name, facility_id, state, measure_name, num_discharges,
 footnote, excess_readmit_ratio, predicted_rate, expected_rate,
 num_readmissions, start_date, end_date);
 
SELECT CONCAT(COUNT(*), ' rows loaded into hospital_readmissions') AS status
FROM hospital_readmissions;

--  DATA QUALITY CHECK 
SELECT 'Running data quality checks...' AS status;
 
-- How many rows total?
SELECT COUNT(*) AS total_rows FROM hospital_readmissions;
 
-- How many NULLs in key numeric columns?
SELECT
    SUM(CASE WHEN excess_readmit_ratio IS NULL THEN 1 ELSE 0 END) AS null_excess_ratio,
    SUM(CASE WHEN predicted_rate       IS NULL THEN 1 ELSE 0 END) AS null_predicted_rate,
    SUM(CASE WHEN state                IS NULL THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN measure_name         IS NULL THEN 1 ELSE 0 END) AS null_measure
FROM hospital_readmissions;
 
-- How many rows have N/A or Too Few to Report for discharges/readmissions?
SELECT
    SUM(CASE WHEN num_discharges    = 'N/A'               THEN 1 ELSE 0 END) AS discharges_na,
    SUM(CASE WHEN num_readmissions  = 'Too Few to Report'  THEN 1 ELSE 0 END) AS readmissions_too_few,
    SUM(CASE WHEN num_readmissions  = 'N/A'               THEN 1 ELSE 0 END) AS readmissions_na
FROM hospital_readmissions;
 
-- What conditions are in the dataset?
SELECT DISTINCT measure_name FROM hospital_readmissions ORDER BY measure_name;
 
-- What does the data actually look like?
SELECT * FROM hospital_readmissions LIMIT 5;

-- ============================================================
--  QUERY 1: State-Level Readmission Overview
--  Which states have the highest average excess readmission ratio?
--  Excess ratio > 1.0 = worse than expected nationally
--  Excess ratio < 1.0 = better than expected nationally
-- ============================================================
 
SELECT 'Query 1: State-level readmission overview' AS status;
 
SELECT
    state,
    COUNT(*)                                        AS total_records,
    COUNT(DISTINCT hospital_name)                   AS hospital_count,
    SUM(CASE WHEN excess_readmit_ratio > 1.0
             THEN 1 ELSE 0 END)                     AS hospitals_above_national,
    SUM(CASE WHEN excess_readmit_ratio <= 1.0
             THEN 1 ELSE 0 END)                     AS hospitals_at_or_below_national,
    ROUND(AVG(excess_readmit_ratio), 4)             AS avg_excess_ratio,
    ROUND(MIN(excess_readmit_ratio), 4)             AS best_ratio,
    ROUND(MAX(excess_readmit_ratio), 4)             AS worst_ratio
FROM hospital_readmissions
WHERE excess_readmit_ratio IS NOT NULL
GROUP BY state
ORDER BY avg_excess_ratio DESC;
 
 
-- ============================================================
--  QUERY 2: Readmission Rate by Condition
--  Which diagnoses drive the most readmissions nationally?
--  Helps identify which conditions need the most attention
-- ============================================================
 
SELECT 'Query 2: Readmission rate by condition' AS status;
 
SELECT
    measure_name,
    COUNT(*)                                         AS hospital_count,
    ROUND(AVG(excess_readmit_ratio), 4)              AS avg_excess_ratio,
    ROUND(MIN(excess_readmit_ratio), 4)              AS best_hospital_ratio,
    ROUND(MAX(excess_readmit_ratio), 4)              AS worst_hospital_ratio,
    SUM(CASE WHEN excess_readmit_ratio > 1.0
             THEN 1 ELSE 0 END)                      AS hospitals_above_national,
    ROUND(
        SUM(CASE WHEN excess_readmit_ratio > 1.0
                 THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 1
    )                                                AS pct_above_national
FROM hospital_readmissions
WHERE excess_readmit_ratio IS NOT NULL
GROUP BY measure_name
ORDER BY avg_excess_ratio DESC;
 
 
-- ============================================================
--  QUERY 3: Performance Tier Distribution
--  Buckets hospitals into risk tiers based on excess ratio
--  Use this in Tableau as a donut or bar chart
-- ============================================================
 
SELECT 'Query 3: Hospital performance tier distribution' AS status;
 
SELECT
    CASE
        WHEN excess_readmit_ratio >= 1.10 THEN '1 - High Risk (10%+ above national)'
        WHEN excess_readmit_ratio >= 1.00 THEN '2 - Above National Average'
        WHEN excess_readmit_ratio >= 0.90 THEN '3 - Below National Average'
        ELSE                                   '4 - Low Risk (10%+ below national)'
    END                                              AS performance_tier,
    COUNT(*)                                         AS hospital_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_total,
    ROUND(AVG(excess_readmit_ratio), 4)              AS avg_excess_ratio
FROM hospital_readmissions
WHERE excess_readmit_ratio IS NOT NULL
GROUP BY performance_tier
ORDER BY performance_tier;
 
 
-- ============================================================
--  QUERY 4: Worst Performing Hospitals
--  Top 20 hospitals with highest excess readmission ratios
--  Filtered to only hospitals with real discharge numbers
--  (excludes N/A rows for reliability)
-- ============================================================
 
SELECT 'Query 4: Worst performing hospitals' AS status;
 
SELECT
    hospital_name,
    state,
    measure_name,
    num_discharges,
    num_readmissions,
    excess_readmit_ratio,
    predicted_rate,
    expected_rate
FROM hospital_readmissions
WHERE excess_readmit_ratio IS NOT NULL
  AND num_discharges NOT IN ('N/A', '')
  AND num_discharges IS NOT NULL
ORDER BY excess_readmit_ratio DESC
LIMIT 20;
 
 
-- ============================================================
--  QUERY 5: Best Performing Hospitals
--  Hospitals consistently beating the national average
--  across at least 3 conditions — signals systemic excellence
-- ============================================================
 
SELECT 'Query 5: Best performing hospitals (3+ conditions)' AS status;
 
SELECT
    hospital_name,
    state,
    COUNT(DISTINCT measure_name)                     AS conditions_tracked,
    ROUND(AVG(excess_readmit_ratio), 4)              AS avg_excess_ratio,
    ROUND(MIN(excess_readmit_ratio), 4)              AS best_condition_ratio,
    ROUND(MAX(excess_readmit_ratio), 4)              AS worst_condition_ratio
FROM hospital_readmissions
WHERE excess_readmit_ratio < 1.0
  AND excess_readmit_ratio IS NOT NULL
  AND num_discharges NOT IN ('N/A', '')
GROUP BY hospital_name, state
HAVING COUNT(DISTINCT measure_name) >= 3
ORDER BY avg_excess_ratio ASC
LIMIT 20;
 
 
-- ============================================================
--  QUERY 6: State + Condition Heatmap
--  Which state/condition combinations are highest risk?
--  Export this to Tableau for a heatmap or filled table
-- ============================================================
 
SELECT 'Query 6: State and condition risk heatmap' AS status;
 
SELECT
    state,
    measure_name,
    COUNT(*)                                         AS hospital_count,
    ROUND(AVG(excess_readmit_ratio), 4)              AS avg_excess_ratio,
    ROUND(MIN(excess_readmit_ratio), 4)              AS best_ratio,
    ROUND(MAX(excess_readmit_ratio), 4)              AS worst_ratio,
    CASE
        WHEN AVG(excess_readmit_ratio) >= 1.10 THEN 'High Risk'
        WHEN AVG(excess_readmit_ratio) >= 1.00 THEN 'Above Average'
        WHEN AVG(excess_readmit_ratio) >= 0.90 THEN 'Below Average'
        ELSE                                        'Low Risk'
    END                                              AS risk_tier
FROM hospital_readmissions
WHERE excess_readmit_ratio IS NOT NULL
GROUP BY state, measure_name
ORDER BY avg_excess_ratio DESC;
 
 
-- ============================================================
--  QUERY 7: Year-Over-Year Context
--  Compare performance across conditions using predicted
--  vs expected rates — gap shows how far off hospitals are
-- ============================================================
 
SELECT 'Query 7: Predicted vs expected rate gap by condition' AS status;
 
SELECT
    measure_name,
    COUNT(*)                                             AS hospital_count,
    ROUND(AVG(predicted_rate), 4)                        AS avg_predicted_rate,
    ROUND(AVG(expected_rate), 4)                         AS avg_expected_rate,
    ROUND(AVG(predicted_rate) - AVG(expected_rate), 4)   AS avg_rate_gap,
    CASE
        WHEN AVG(predicted_rate) > AVG(expected_rate)
        THEN 'Performing Worse Than Expected'
        ELSE 'Performing Better Than Expected'
    END                                                  AS overall_assessment
FROM hospital_readmissions
WHERE predicted_rate IS NOT NULL
  AND expected_rate  IS NOT NULL
GROUP BY measure_name
ORDER BY avg_rate_gap DESC;
 
 
-- ============================================================
--  QUERY 8: Summary Dashboard Metrics
--  Single-row KPI summary — pull into Tableau summary cards
-- ============================================================
 
SELECT 'Query 8: Summary dashboard metrics' AS status;
 
SELECT
    COUNT(DISTINCT hospital_name)                    AS total_hospitals,
    COUNT(DISTINCT state)                            AS total_states,
    COUNT(DISTINCT measure_name)                     AS total_conditions,
    COUNT(*)                                         AS total_records,
    ROUND(AVG(excess_readmit_ratio), 4)              AS national_avg_excess_ratio,
    SUM(CASE WHEN excess_readmit_ratio > 1.0
             THEN 1 ELSE 0 END)                      AS records_above_national,
    SUM(CASE WHEN excess_readmit_ratio <= 1.0
             THEN 1 ELSE 0 END)                      AS records_at_or_below_national,
    ROUND(
        SUM(CASE WHEN excess_readmit_ratio > 1.0
                 THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 1
    )                                                AS pct_above_national
FROM hospital_readmissions
WHERE excess_readmit_ratio IS NOT NULL;
 
SELECT 'Analysis complete! Ready for Tableau.' AS status;