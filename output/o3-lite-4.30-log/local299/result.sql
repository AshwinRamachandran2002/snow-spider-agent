WITH RECURSIVE
    /* 1 ─ net movement per customer‑day */
    daily_net AS (
        SELECT
            "customer_id",
            "txn_date"                                   AS d,
            SUM(CASE WHEN "txn_type" = 'deposit'
                     THEN  "txn_amount"
                     ELSE - "txn_amount" END)            AS net_amt
        FROM "customer_transactions"
        GROUP BY "customer_id", "txn_date"
    ),
    /* 2 ─ activity span + baseline month per customer */
    cust_span AS (
        SELECT
            "customer_id",
            MIN("txn_date")                              AS start_d,
            MAX("txn_date")                              AS end_d,
            SUBSTR(MIN("txn_date"),1,7)                  AS base_month
        FROM "customer_transactions"
        GROUP BY "customer_id"
    ),
    /* 3 ─ complete calendar of days for every customer */
    date_calendar AS (
        SELECT
            "customer_id",
            start_d                                      AS d,
            end_d
        FROM cust_span
        UNION ALL
        SELECT
            "customer_id",
            DATE(d,'+1 day')                             AS d,
            end_d
        FROM date_calendar
        WHERE d < end_d
    ),
    /* 4 ─ daily balances (0 on non‑transaction days) */
    daily_balances AS (
        SELECT
            dc."customer_id",
            dc.d,
            COALESCE(dn.net_amt,0)                       AS net_amt
        FROM date_calendar dc
        LEFT JOIN daily_net dn
               ON dn."customer_id" = dc."customer_id"
              AND dn.d            = dc.d
    ),
    /* 5 ─ running cumulative balance */
    running_bal AS (
        SELECT
            "customer_id",
            d,
            SUM(net_amt) OVER (
                PARTITION BY "customer_id"
                ORDER BY d
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )                                           AS balance
        FROM daily_balances
    ),
    /* 6 ─ 30‑day rolling average (≥30 days, negatives floored) */
    rolling30 AS (
        SELECT
            "customer_id",
            d,
            ROW_NUMBER() OVER (PARTITION BY "customer_id" ORDER BY d) AS rn,
            AVG(balance) OVER (
                PARTITION BY "customer_id"
                ORDER BY d
                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
            )                                           AS avg30_raw
        FROM running_bal
    ),
    rolling30_valid AS (
        SELECT
            "customer_id",
            d,
            CASE WHEN avg30_raw < 0 THEN 0 ELSE avg30_raw END AS avg30
        FROM rolling30
        WHERE rn >= 30
    ),
    /* 7 ─ monthly max 30‑day average per customer */
    cust_month_max AS (
        SELECT
            "customer_id",
            SUBSTR(d,1,7)                               AS month,
            MAX(avg30)                                  AS max_30day_avg
        FROM rolling30_valid
        GROUP BY "customer_id", month
    ),
    /* 8 ─ drop each customer's baseline month */
    cust_month_max_no_base AS (
        SELECT cm.*
        FROM   cust_month_max cm
        JOIN   cust_span       cs
               ON cm."customer_id" = cs."customer_id"
        WHERE  cm.month <> cs.base_month
    )
/* 9 ─ final monthly totals across all customers */
SELECT
    month,
    ROUND(SUM(max_30day_avg),4) AS total_max_30day_avg_balance
FROM   cust_month_max_no_base
GROUP  BY month
ORDER  BY month;