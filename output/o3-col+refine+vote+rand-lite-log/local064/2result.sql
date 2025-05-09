WITH monthly_balances AS (           -- 1. month-end balance for every customer in 2020
    SELECT  "customer_id",
            substr("txn_date",1,7)               AS "month",          -- YYYY-MM
            SUM(CASE
                    WHEN "txn_type" = 'deposit'    THEN  "txn_amount"
                    WHEN "txn_type" = 'withdrawal' THEN - "txn_amount"
                    ELSE 0
                END)                             AS "month_end_balance"
    FROM    "customer_transactions"
    WHERE   "txn_date" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP   BY "customer_id","month"
),
positive_counts AS (                 -- 2. customers with positive balances per month
    SELECT  "month",
            COUNT(*) AS pos_customer_cnt
    FROM    monthly_balances
    WHERE   "month_end_balance" > 0
    GROUP   BY "month"
),
hi_lo_months AS (                    -- 3. month with most vs. fewest positive customers
    SELECT  (SELECT "month"
             FROM   positive_counts
             ORDER  BY pos_customer_cnt DESC, "month"
             LIMIT  1) AS hi_month,
            (SELECT "month"
             FROM   positive_counts
             ORDER  BY pos_customer_cnt ASC,  "month"
             LIMIT  1) AS lo_month
),
avg_balances AS (                    -- 4. average month-end balance for those two months
    SELECT 'hi' AS label,
           ROUND(AVG("month_end_balance"),4) AS avg_balance
    FROM   monthly_balances
    WHERE  "month" = (SELECT hi_month FROM hi_lo_months)
    UNION ALL
    SELECT 'lo',
           ROUND(AVG("month_end_balance"),4)
    FROM   monthly_balances
    WHERE  "month" = (SELECT lo_month FROM hi_lo_months)
),
pivot AS (                           -- 5. pivot hi/lo averages to single row
    SELECT MAX(CASE WHEN label='hi' THEN avg_balance END) AS hi_avg_balance,
           MAX(CASE WHEN label='lo' THEN avg_balance END) AS lo_avg_balance
    FROM   avg_balances
)
SELECT  (SELECT hi_month FROM hi_lo_months)               AS highest_positive_month,
        (SELECT lo_month FROM hi_lo_months)               AS lowest_positive_month,
        hi_avg_balance,
        lo_avg_balance,
        ROUND(hi_avg_balance - lo_avg_balance,4)          AS avg_balance_difference
FROM    pivot;