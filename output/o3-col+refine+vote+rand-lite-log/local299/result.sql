/* ------------------------------------------------------------
   Monthly totals of customers’ maximum 30-day running-balance
   averages (baseline month for every customer excluded)
------------------------------------------------------------*/
WITH RECURSIVE
-- 1. date span for every customer
date_bounds AS (
    SELECT
        "customer_id",
        DATE(MIN("txn_date")) AS "start_date",
        DATE(MAX("txn_date")) AS "end_date"
    FROM "customer_transactions"
    GROUP BY "customer_id"
),
-- 2. day-by-day calendar for every customer
date_series AS (
    SELECT
        db."customer_id",
        db."start_date" AS "txn_date",
        db."end_date"
    FROM date_bounds db
    UNION ALL
    SELECT
        ds."customer_id",
        DATE(ds."txn_date", '+1 day'),
        ds."end_date"
    FROM date_series ds
    WHERE DATE(ds."txn_date") < ds."end_date"
),
-- 3. net daily movement (missing days treated as 0)
daily_net AS (
    SELECT
        ds."customer_id",
        ds."txn_date",
        COALESCE(
            SUM(
                CASE WHEN ct."txn_type" = 'deposit'
                     THEN  ct."txn_amount"
                     ELSE -ct."txn_amount"
                END
            ), 0
        ) AS "net_amount"
    FROM date_series ds
    LEFT JOIN "customer_transactions" ct
           ON ct."customer_id" = ds."customer_id"
          AND DATE(ct."txn_date") = ds."txn_date"
    GROUP BY ds."customer_id", ds."txn_date"
),
-- 4. running balance
running_balance AS (
    SELECT
        dn."customer_id",
        dn."txn_date",
        SUM(dn."net_amount") OVER (
            PARTITION BY dn."customer_id"
            ORDER BY       dn."txn_date"
        ) AS "running_balance"
    FROM daily_net dn
),
-- 5. 30-day rolling average (negative averages coerced to 0)
rolling_avg AS (
    SELECT
        rb."customer_id",
        rb."txn_date",
        MAX(0,
            AVG(rb."running_balance") OVER (
                PARTITION BY rb."customer_id"
                ORDER BY       rb."txn_date"
                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
            )
        ) AS "avg_30d_bal",
        COUNT(*) OVER (
            PARTITION BY rb."customer_id"
            ORDER BY       rb."txn_date"
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS "row_cnt"
    FROM running_balance rb
),
-- 6. retain rows only after a full 30-day history exists
rolling_30d AS (
    SELECT
        "customer_id",
        "txn_date",
        "avg_30d_bal"
    FROM rolling_avg
    WHERE "row_cnt" = 30
),
-- 7. customer-month maximum of those 30-day averages
monthly_max AS (
    SELECT
        "customer_id",
        strftime('%Y-%m', "txn_date") AS "year_month",
        MAX("avg_30d_bal")            AS "max_30d_bal"
    FROM rolling_30d
    GROUP BY "customer_id", strftime('%Y-%m', "txn_date")
),
-- 8. identify each customer’s baseline (first) month
baseline_month AS (
    SELECT
        "customer_id",
        strftime('%Y-%m', MIN(DATE("txn_date"))) AS "baseline_month"
    FROM "customer_transactions"
    GROUP BY "customer_id"
),
-- 9. exclude baseline month figures
monthly_max_excl AS (
    SELECT mm.*
    FROM monthly_max  mm
    JOIN baseline_month bm
      ON mm."customer_id" = bm."customer_id"
    WHERE mm."year_month" <> bm."baseline_month"
)
-- 10. final monthly totals across all customers
SELECT
    "year_month",
    ROUND(SUM("max_30d_bal"), 4) AS "total_max_30d_bal"
FROM monthly_max_excl
GROUP BY "year_month"
ORDER BY "year_month";