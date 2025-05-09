WITH date_range AS (
    SELECT 
        MIN(DATE_TRUNC('month', TO_DATE("txn_date", 'YYYY-MM-DD'))) AS min_month,
        MAX(DATE_TRUNC('month', TO_DATE("txn_date", 'YYYY-MM-DD'))) AS max_month
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),
months AS (
    SELECT min_month AS month_start
    FROM date_range
    UNION ALL
    SELECT DATEADD(month, 1, month_start)
    FROM months
    WHERE DATEADD(month, 1, month_start) <= (SELECT max_month FROM date_range)
),
customers AS (
    SELECT DISTINCT "customer_id"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),
customer_months AS (
    SELECT 
        c."customer_id", 
        m.month_start
    FROM customers c
    CROSS JOIN months m
),
txn_monthly AS (
    SELECT
        "customer_id",
        DATE_TRUNC('month', TO_DATE("txn_date", 'YYYY-MM-DD')) AS month_start,
        SUM(
            CASE 
                WHEN "txn_type" = 'deposit' THEN "txn_amount"
                WHEN "txn_type" IN ('withdrawal', 'purchase') THEN - "txn_amount"
                ELSE 0
            END
        ) AS monthly_change
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    GROUP BY "customer_id", DATE_TRUNC('month', TO_DATE("txn_date", 'YYYY-MM-DD'))
),
customer_balances AS (
    SELECT 
        cm."customer_id", 
        cm.month_start,
        COALESCE(tm.monthly_change, 0) AS monthly_change
    FROM customer_months cm
    LEFT JOIN txn_monthly tm
        ON cm."customer_id" = tm."customer_id"
        AND cm.month_start = tm.month_start
),
customer_balances_with_cumulative AS (
    SELECT
        "customer_id",
        month_start,
        monthly_change,
        SUM(monthly_change) OVER (
            PARTITION BY "customer_id"
            ORDER BY month_start
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_balance
    FROM customer_balances
)
SELECT
    "customer_id",
    TO_VARCHAR(month_start, 'YYYY-MM') AS "month",
    ROUND(monthly_change, 4) AS "monthly_change",
    ROUND(cumulative_balance, 4) AS "cumulative_balance"
FROM customer_balances_with_cumulative
ORDER BY "customer_id", month_start;