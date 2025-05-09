WITH RECURSIVE months(month_start) AS (
    /* generate every calendar month between the first and last transaction */
    SELECT date((SELECT MIN("txn_date") FROM "customer_transactions"), 'start of month')
    UNION ALL
    SELECT date(month_start, '+1 month')
    FROM   months
    WHERE  month_start < date((SELECT MAX("txn_date") FROM "customer_transactions"), 'start of month')
),
month_list AS (
    SELECT strftime('%Y-%m', month_start) AS year_month
    FROM   months
),
customers AS (
    SELECT DISTINCT "customer_id"
    FROM   "customer_transactions"
),
cust_month AS (
    /* ensure each customer has a record for every month */
    SELECT  c."customer_id",
            m.year_month
    FROM    customers  c
    CROSS JOIN month_list m
),
monthly_change AS (
    /* deposits are positive; withdrawals, purchases, and any non‑deposit are negative */
    SELECT  "customer_id",
            substr("txn_date", 1, 7) AS year_month,
            SUM(CASE WHEN "txn_type" = 'deposit'
                     THEN  "txn_amount"
                     ELSE - "txn_amount"
                END) AS monthly_change
    FROM    "customer_transactions"
    GROUP BY "customer_id", substr("txn_date", 1, 7)
),
combined AS (
    SELECT  cm."customer_id",
            cm.year_month,
            COALESCE(mc.monthly_change, 0) AS monthly_change
    FROM    cust_month      cm
    LEFT JOIN monthly_change mc
           ON cm."customer_id" = mc."customer_id"
          AND cm.year_month   = mc.year_month
)
SELECT  "customer_id",
        date(year_month || '-01', 'start of month', '+1 month', '-1 day') AS month_end,
        printf('%.4f', monthly_change)                                    AS monthly_change,
        printf('%.4f',
               SUM(monthly_change) OVER (
                   PARTITION BY "customer_id"
                   ORDER BY year_month
               )
        )                                                                 AS closing_balance
FROM    combined
ORDER BY "customer_id", month_end;