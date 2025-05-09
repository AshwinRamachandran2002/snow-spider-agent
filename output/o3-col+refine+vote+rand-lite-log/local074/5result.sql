WITH monthly_change AS (
    /* 1.  Net change (+ deposits, – withdrawals) per customer & month */
    SELECT
        "customer_id",
        substr("txn_date",1,7)          AS "year_month",        -- YYYY-MM
        SUM(CASE
                WHEN lower("txn_type")='deposit'    THEN  1 * "txn_amount"
                WHEN lower("txn_type")='withdrawal' THEN -1 * "txn_amount"
                ELSE 0
            END)                      AS "monthly_net_change"
    FROM "customer_transactions"
    GROUP BY "customer_id", substr("txn_date",1,7)
),
customers AS (
    /* 2.  List of all customers that appear in the data */
    SELECT DISTINCT "customer_id"
    FROM "customer_transactions"
),
month_bounds AS (
    /* 3.  Global first and last month in the dataset */
    SELECT
        MIN(date(substr("txn_date",1,7) || '-01')) AS min_month,
        MAX(date(substr("txn_date",1,7) || '-01')) AS max_month
    FROM "customer_transactions"
),
/* 4.  Recursive list of every calendar month between the bounds */
month_list("year_month") AS (
    SELECT strftime('%Y-%m', min_month) FROM month_bounds
    UNION ALL
    SELECT strftime('%Y-%m', date("year_month"||'-01','+1 month'))
    FROM month_list, month_bounds
    WHERE date("year_month"||'-01') < max_month
),
/* 5.  Cartesian grid so every customer has every month */
customer_month_grid AS (
    SELECT c."customer_id", m."year_month"
    FROM customers c
    CROSS JOIN month_list m
),
/* 6.  Merge grid with real activity, defaulting missing months to 0 */
grid_with_change AS (
    SELECT
        g."customer_id",
        g."year_month",
        COALESCE(mc."monthly_net_change",0) AS "monthly_net_change"
    FROM customer_month_grid g
    LEFT JOIN monthly_change mc
      ON mc."customer_id" = g."customer_id"
     AND mc."year_month"  = g."year_month"
)
/* 7.  Final output – monthly change and running balance */
SELECT
    "customer_id",
    "year_month",
    "monthly_net_change",
    SUM("monthly_net_change") OVER (
        PARTITION BY "customer_id"
        ORDER BY "year_month"
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS "closing_balance"
FROM grid_with_change
ORDER BY "customer_id", "year_month";