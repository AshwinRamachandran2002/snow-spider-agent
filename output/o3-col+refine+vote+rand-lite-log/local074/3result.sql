WITH
/* 1 ── overall date limits in the ledger */
date_bounds AS (
    SELECT
        MIN(date("txn_date")) AS min_dt,
        MAX(date("txn_date")) AS max_dt
    FROM "customer_transactions"
),
/* 2 ── contiguous list of every calendar month in that range */
months(month_year) AS (
        SELECT strftime('%Y-%m', min_dt)           -- first month
        FROM   date_bounds
    UNION ALL
        SELECT strftime('%Y-%m',
                       date(month_year||'-01', '+1 month'))
        FROM   months, date_bounds
        WHERE  month_year < strftime('%Y-%m', max_dt)
),
/* 3 ── list of all customers that ever appeared in the ledger */
customers AS (
    SELECT DISTINCT "customer_id"
    FROM   "customer_transactions"
),
/* 4 ── every customer × every month (ensures no gaps) */
calendar AS (
    SELECT  c."customer_id",
            m."month_year"
    FROM    customers c
    CROSS   JOIN months m
),
/* 5 ── net movement (positive = deposit, negative = out-flow) */
net_change AS (
    SELECT
        "customer_id",
        strftime('%Y-%m', "txn_date") AS month_year,
        SUM( CASE
                 WHEN "txn_type" = 'deposit'      THEN  + "txn_amount"
                 ELSE                                   - "txn_amount"
             END ) AS monthly_change
    FROM    "customer_transactions"
    GROUP   BY "customer_id", month_year
),
/* 6 ── attach the movements to the full customer-month frame */
joined AS (
    SELECT
        cal."customer_id",
        cal."month_year",
        COALESCE(nc."monthly_change", 0) AS monthly_change
    FROM   calendar cal
    LEFT   JOIN net_change nc
           ON  nc."customer_id" = cal."customer_id"
           AND nc."month_year"  = cal."month_year"
)
/* 7 ── final report: monthly change & running closing balance */
SELECT
    "customer_id",
    "month_year",
    "monthly_change",
    SUM("monthly_change") OVER (
        PARTITION BY "customer_id"
        ORDER BY      "month_year"
    ) AS closing_balance
FROM   joined
ORDER  BY "customer_id", "month_year";