/* ------------------------------------------------------------
   Build monthly totals of customers’ peak 30-day average
   balances, ignoring each customer’s very first month.
------------------------------------------------------------- */

WITH daily_net AS (                       -- net amount per customer/date
    SELECT  "customer_id",
            DATE("txn_date")                                    AS "dte",
            SUM(CASE WHEN "txn_type" = 'deposit'
                     THEN  "txn_amount"
                     ELSE -1 * "txn_amount" END)               AS "net_amt"
    FROM    "customer_transactions"
    GROUP   BY "customer_id", DATE("txn_date")
),

running_bal AS (                          -- running balance
    SELECT  "customer_id",
            "dte",
            SUM("net_amt") OVER (
                 PARTITION BY "customer_id"
                 ORDER BY     "dte"
                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS "running_balance"
    FROM    daily_net
),

rolling_30 AS (                           -- 30-day rolling average balance
    SELECT  "customer_id",
            "dte",
            AVG("running_balance") OVER (
                 PARTITION BY "customer_id"
                 ORDER BY     "dte"
                 ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
            ) AS "avg_30d"
    FROM    running_bal
),

first_txn AS (                            -- first txn date per customer
    SELECT  "customer_id",
            MIN(DATE("txn_date")) AS "first_dte"
    FROM    "customer_transactions"
    GROUP   BY "customer_id"
),

valid_rolling AS (                        -- only after 30 calendar days, floor negatives
    SELECT  r."customer_id",
            r."dte",
            CASE WHEN r."avg_30d" < 0 THEN 0 ELSE r."avg_30d" END AS "clean_avg_30d"
    FROM    rolling_30  AS r
    JOIN    first_txn   AS f
      ON    r."customer_id" = f."customer_id"
    WHERE   JULIANDAY(r."dte") - JULIANDAY(f."first_dte") >= 29   -- ≥30-day history
),

cust_monthly_peak AS (                    -- monthly peak per customer
    SELECT  "customer_id",
            STRFTIME('%Y-%m', "dte")              AS "month",
            MAX("clean_avg_30d")                  AS "max_30d_avg_in_month"
    FROM    valid_rolling
    GROUP   BY "customer_id", STRFTIME('%Y-%m', "dte")
),

baseline_month AS (                       -- customer’s first month
    SELECT  "customer_id",
            MIN(STRFTIME('%Y-%m', "txn_date"))   AS "first_month"
    FROM    "customer_transactions"
    GROUP   BY "customer_id"
)

SELECT  cmp."month",
        ROUND(SUM(cmp."max_30d_avg_in_month"), 4) AS "sum_of_monthly_customer_maxes"
FROM    cust_monthly_peak AS cmp
JOIN    baseline_month   AS bm
  ON    cmp."customer_id" = bm."customer_id"
WHERE   cmp."month" <> bm."first_month"          -- exclude baseline month
GROUP   BY cmp."month"
ORDER   BY cmp."month";