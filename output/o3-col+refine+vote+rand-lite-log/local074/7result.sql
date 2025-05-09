WITH
/* 1. List of every distinct customer */
customers AS (
    SELECT DISTINCT "customer_id"
    FROM "customer_transactions"
),

/* 2. Continuous list of months that span the data set */
months AS (
    WITH RECURSIVE m(d) AS (
        SELECT DATE((SELECT MIN("txn_date") FROM "customer_transactions"), 'start of month')
        UNION ALL
        SELECT DATE(d, '+1 month')
        FROM   m
        WHERE  d < DATE((SELECT MAX("txn_date") FROM "customer_transactions"), 'start of month')
    )
    SELECT strftime('%Y-%m', d) AS "month_year"
    FROM   m
),

/* 3. Cartesian product → every customer for every month */
base_grid AS (
    SELECT c."customer_id",
           m."month_year"
    FROM   customers c
    CROSS  JOIN months    m
),

/* 4. Net change for each customer-month (+ deposit, − withdrawal) */
monthly_txn AS (
    SELECT "customer_id",
           strftime('%Y-%m', "txn_date") AS "month_year",
           SUM(CASE
                   WHEN "txn_type" = 'deposit'    THEN  "txn_amount"
                   WHEN "txn_type" = 'withdrawal' THEN - "txn_amount"
                   ELSE 0
               END)                        AS "monthly_change"
    FROM   "customer_transactions"
    GROUP  BY "customer_id", "month_year"
),

/* 5. Merge grid with actual changes, filling gaps with zero */
combined AS (
    SELECT  g."customer_id",
            g."month_year",
            COALESCE(t."monthly_change", 0) AS "monthly_change"
    FROM    base_grid  g
    LEFT    JOIN monthly_txn t
           ON g."customer_id" = t."customer_id"
          AND g."month_year" = t."month_year"
)

/* 6. Final output – monthly change and running (closing) balance */
SELECT  "customer_id",
        "month_year",
        "monthly_change",
        SUM("monthly_change") OVER (PARTITION BY "customer_id"
                                    ORDER BY "month_year") AS "closing_balance"
FROM    combined
ORDER BY "customer_id", "month_year";