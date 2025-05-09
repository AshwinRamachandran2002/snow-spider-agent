/*  Monthly change and running (closing) balance per customer
    – gaps filled so every month between a customer’s first and last
      transaction is listed, even when no activity occurred            */

WITH date_bounds AS (                 -- 1. first & last month per customer
    SELECT
        "customer_id",
        MIN(date(substr("txn_date",1,7) || '-01')) AS min_month,
        MAX(date(substr("txn_date",1,7) || '-01')) AS max_month
    FROM   "customer_transactions"
    GROUP  BY "customer_id"
),
recursive_months AS (                 -- 2. build month-by-month calendar
    SELECT
        "customer_id",
        min_month AS month_start
    FROM   date_bounds
    UNION ALL
    SELECT
        rm."customer_id",
        date(rm.month_start,'+1 month')
    FROM   recursive_months rm
    JOIN   date_bounds     db  ON db."customer_id" = rm."customer_id"
    WHERE  rm.month_start < db.max_month           -- stop at last month
),
month_calendar AS (                   -- 3. human-readable YYYY-MM label
    SELECT
        "customer_id",
        strftime('%Y-%m', month_start) AS month_year
    FROM   recursive_months
),
monthly_change AS (                   -- 4. sign deposits +, withdrawals –
    SELECT
        "customer_id",
        substr("txn_date",1,7)        AS month_year,
        SUM(CASE
                WHEN "txn_type"='deposit'    THEN  "txn_amount"
                WHEN "txn_type"='withdrawal' THEN -1 * "txn_amount"
                ELSE 0
            END)                      AS monthly_change
    FROM   "customer_transactions"
    GROUP  BY "customer_id", month_year
)
SELECT
    cal."customer_id",
    cal."month_year",
    COALESCE(mc.monthly_change,0)                                      AS monthly_change,
    SUM(COALESCE(mc.monthly_change,0)) OVER (
        PARTITION BY cal."customer_id"
        ORDER BY     cal."month_year"
    )                                                                  AS closing_balance
FROM   month_calendar cal
LEFT   JOIN monthly_change mc
       ON  cal."customer_id" = mc."customer_id"
       AND cal."month_year"  = mc."month_year"
ORDER  BY cal."customer_id", cal."month_year";