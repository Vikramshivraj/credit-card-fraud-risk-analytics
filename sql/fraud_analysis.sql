-- ============================================================
-- Credit Card Fraud Risk Analytics - SQL analysis (SQLite)
--
-- Tables (the notebook creates both inside data/fraud.db):
--   transactions        raw 284,807 rows: Time, V1..V28, Amount, Class, hour
--   scored_transactions model output on the 56,746-row test set:
--                       TransactionID, TransactionAmount, Hour, FraudProbability,
--                       RiskScore, RiskLevel, ActualOutcome
--
-- Run in VS Code: install the "SQLite Viewer" or "SQLTools + SQLite" extension,
-- open data/fraud.db, then run each query. Every query starts with "-- Q<number>".
-- ============================================================

-- Q1: Overall fraud rate
SELECT
    COUNT(*)                                             AS total_transactions,
    SUM(Class)                                           AS fraud_transactions,
    ROUND(100.0 * SUM(Class) / COUNT(*), 4)              AS fraud_rate_pct
FROM transactions;

-- Q2: Fraud rate by hour of day (highest first)
SELECT
    hour,
    COUNT(*)                                             AS total_txns,
    SUM(Class)                                           AS fraud_txns,
    ROUND(100.0 * SUM(Class) / COUNT(*), 4)              AS fraud_rate_pct
FROM transactions
GROUP BY hour
ORDER BY fraud_rate_pct DESC;

-- Q3: Amount statistics, fraud vs legitimate
SELECT
    CASE WHEN Class = 1 THEN 'Fraud' ELSE 'Legitimate' END AS outcome,
    COUNT(*)                AS txn_count,
    ROUND(AVG(Amount), 2)   AS avg_amount,
    ROUND(MIN(Amount), 2)   AS min_amount,
    ROUND(MAX(Amount), 2)   AS max_amount
FROM transactions
GROUP BY Class;

-- Q4: Ten largest fraudulent transactions
SELECT Time, hour, Amount
FROM transactions
WHERE Class = 1
ORDER BY Amount DESC
LIMIT 10;

-- Q5: Fraud rate by amount bucket
SELECT
    CASE
        WHEN Amount < 10  THEN '1. Under 10'
        WHEN Amount < 100 THEN '2. 10 to 100'
        WHEN Amount < 500 THEN '3. 100 to 500'
        ELSE                   '4. 500 and above'
    END AS amount_bucket,
    COUNT(*)                                             AS total_txns,
    SUM(Class)                                           AS fraud_txns,
    ROUND(100.0 * SUM(Class) / COUNT(*), 4)              AS fraud_rate_pct
FROM transactions
GROUP BY amount_bucket
ORDER BY amount_bucket;

-- Q6: Night (1 AM-5 AM) vs rest of day
SELECT
    CASE WHEN hour BETWEEN 1 AND 5 THEN 'Night (1-5 AM)' ELSE 'Rest of day' END AS period,
    COUNT(*)                                             AS total_txns,
    SUM(Class)                                           AS fraud_txns,
    ROUND(100.0 * SUM(Class) / COUNT(*), 4)              AS fraud_rate_pct
FROM transactions
GROUP BY period;

-- Q7: Exact duplicate rows (data quality). Uses a CTE (WITH ... AS).
WITH grouped AS (
    SELECT COUNT(*) AS copies
    FROM transactions
    GROUP BY Time, V1, V2, V3, V4, V5, V6, V7, V8, V9, V10, V11, V12, V13, V14,
             V15, V16, V17, V18, V19, V20, V21, V22, V23, V24, V25, V26, V27, V28,
             Amount, Class
)
SELECT
    SUM(copies)                             AS total_rows,
    COUNT(*)                                AS unique_rows,
    SUM(copies) - COUNT(*)                  AS duplicate_rows_to_remove
FROM grouped;

-- Q8: Hours whose fraud rate is above the overall rate (subquery + HAVING)
SELECT
    hour,
    COUNT(*)                                             AS total_txns,
    SUM(Class)                                           AS fraud_txns,
    ROUND(100.0 * SUM(Class) / COUNT(*), 3)              AS fraud_rate_pct
FROM transactions
GROUP BY hour
HAVING 1.0 * SUM(Class) / COUNT(*) > (SELECT 1.0 * SUM(Class) / COUNT(*) FROM transactions)
ORDER BY fraud_rate_pct DESC;

-- Q9: Running (cumulative) share of all fraud by hour (window function)
WITH by_hour AS (
    SELECT hour, SUM(Class) AS fraud_txns
    FROM transactions
    GROUP BY hour
)
SELECT
    hour,
    fraud_txns,
    SUM(fraud_txns) OVER (ORDER BY hour)                                          AS cumulative_fraud,
    ROUND(100.0 * SUM(fraud_txns) OVER (ORDER BY hour) / SUM(fraud_txns) OVER (), 1) AS cumulative_pct_of_fraud
FROM by_hour
ORDER BY hour;

-- Q10: Risk-tier summary of the model output (counts and dollars)
SELECT
    RiskLevel,
    COUNT(*)                                                           AS txns,
    SUM(CASE WHEN ActualOutcome = 'Fraud' THEN 1 ELSE 0 END)           AS fraud_txns,
    ROUND(100.0 * SUM(CASE WHEN ActualOutcome = 'Fraud' THEN 1 ELSE 0 END) / COUNT(*), 2) AS fraud_pct_of_tier,
    ROUND(SUM(TransactionAmount), 0)                                   AS total_value,
    ROUND(SUM(CASE WHEN ActualOutcome = 'Fraud' THEN TransactionAmount ELSE 0 END), 0) AS fraud_value
FROM scored_transactions
GROUP BY RiskLevel
ORDER BY CASE RiskLevel WHEN 'High' THEN 1 WHEN 'Medium' THEN 2 ELSE 3 END;
