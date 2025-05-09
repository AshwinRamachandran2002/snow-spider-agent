WITH monthly_balances AS (
    /* 1. Month-end balance for every customer & 2020 month */
    SELECT
        "customer_id",
        substr("txn_date", 1, 7)                AS month_yyyy_mm,          -- e.g. 2020-03
        SUM(CASE
                WHEN "txn_type" = 'deposit'    THEN  "txn_amount"
                WHEN "txn_type" = 'withdrawal' THEN - "txn_amount"
                ELSE 0
            END)                               AS month_end_balance
    FROM   "customer_transactions"
    WHERE  "txn_date" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP  BY "customer_id", substr("txn_date", 1, 7)
),
positive_counts AS (
    /* 2. For each month, how many customers finished positive? */
    SELECT  month_yyyy_mm,
            COUNT(*) AS pos_cnt
    FROM    monthly_balances
    WHERE   month_end_balance > 0
    GROUP   BY month_yyyy_mm
),
hi_lo_months AS (
    /* 3. Identify the highest-positive and lowest-positive months */
    SELECT month_yyyy_mm
    FROM   positive_counts
    WHERE  pos_cnt = (SELECT MAX(pos_cnt) FROM positive_counts)
       OR  pos_cnt = (SELECT MIN(pos_cnt) FROM positive_counts)
),
avg_balances AS (
    /* 4. Average month-end balance for those two months */
    SELECT  month_yyyy_mm,
            AVG(month_end_balance) AS avg_bal
    FROM    monthly_balances
    WHERE   month_yyyy_mm IN (SELECT month_yyyy_mm FROM hi_lo_months)
    GROUP   BY month_yyyy_mm
)
/* 5. Difference between the two averages */
SELECT
    ROUND(MAX(avg_bal) - MIN(avg_bal), 4) AS difference_between_averages
FROM   avg_balances;