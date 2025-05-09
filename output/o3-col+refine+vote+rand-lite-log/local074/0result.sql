/*  Closing balance per customer per month with zero-activity months kept  */
WITH
-- 1. Find first and last transaction dates to build a complete month list
bounds AS (
    SELECT MIN("txn_date") AS min_date,
           MAX("txn_date") AS max_date
    FROM   "customer_transactions"
),
-- 2. Recursive month calendar between the bounds (YYYY-MM format)
months(month) AS (
    SELECT substr(min_date,1,7) FROM bounds
    UNION ALL
    SELECT substr(date(month || '-01','+1 month'),1,7)
    FROM   months, bounds
    WHERE  month < substr(max_date,1,7)
),
-- 3. Distinct customers
customers AS (
    SELECT DISTINCT "customer_id"
    FROM   "customer_transactions"
),
-- 4. Net change (deposits − withdrawals) by customer & month
monthly_change AS (
    SELECT  "customer_id",
            substr("txn_date",1,7)           AS month,
            SUM(CASE WHEN "txn_type"='deposit'    THEN  "txn_amount"
                     WHEN "txn_type"='withdrawal' THEN - "txn_amount"
                     ELSE 0 END)             AS net_change
    FROM    "customer_transactions"
    GROUP BY "customer_id",
             substr("txn_date",1,7)
),
-- 5. All customer-month combinations (ensures zero-activity months)
calendar AS (
    SELECT m.month,
           c.customer_id
    FROM   months     AS m
    CROSS  JOIN customers AS c
)
-- 6. Final output: net change + running (closing) balance
SELECT  cal.month                                  AS month_year,
        cal.customer_id,
        COALESCE(mc.net_change,0)                  AS monthly_net_change,
        SUM(COALESCE(mc.net_change,0)) OVER (
            PARTITION BY cal.customer_id
            ORDER BY     cal.month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                          AS closing_balance
FROM    calendar       AS cal
LEFT    JOIN monthly_change AS mc
           ON mc.customer_id = cal.customer_id
          AND mc.month       = cal.month
ORDER BY cal.customer_id,
         cal.month;