/*  Sum of each customer’s monthly maximum 30‑day rolling‑average balance
    (negatives clipped to 0, calculated only after a full 30‑day window),
    excluding the customer’s baseline (first) month.  */

WITH daily_amounts AS (                 -- net amount per customer per day
    SELECT  "customer_id",
            DATE("txn_date")                          AS txn_day,
            SUM( CASE WHEN "txn_type" = 'deposit'
                      THEN  "txn_amount"
                      ELSE - "txn_amount" END )       AS net_amount
    FROM    "customer_transactions"
    GROUP   BY "customer_id", txn_day
),
daily_running AS (                      -- running balance per day
    SELECT  da."customer_id",
            da.txn_day,
            SUM(da.net_amount) OVER (
                PARTITION BY da."customer_id"
                ORDER BY      da.txn_day
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS running_balance
    FROM    daily_amounts AS da
),
rolling_30 AS (                         -- 30‑day rolling average balance
    SELECT  dr."customer_id",
            dr.txn_day,
            CASE
                /* use result only after a full 30‑day window exists */
                WHEN COUNT(*) OVER (
                         PARTITION BY dr."customer_id"
                         ORDER BY      dr.txn_day
                         ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
                     ) = 30
                THEN  -- clip negatives to 0
                     MAX(
                         AVG(dr.running_balance) OVER (
                             PARTITION BY dr."customer_id"
                             ORDER BY      dr.txn_day
                             ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
                         ), 0
                     )
                ELSE NULL
            END AS rolling_30d_avg_bal
    FROM    daily_running AS dr
),
month_max AS (                          -- max rolling‑avg per customer/month
    SELECT  "customer_id",
            STRFTIME('%Y-%m', txn_day)  AS year_month,
            MAX(rolling_30d_avg_bal)    AS max_30d_avg_bal
    FROM    rolling_30
    GROUP   BY "customer_id", year_month
),
first_month AS (                        -- each customer’s baseline month
    SELECT  "customer_id",
            MIN( STRFTIME('%Y-%m', "txn_date") ) AS first_month
    FROM    "customer_transactions"
    GROUP   BY "customer_id"
),
exclude_baseline AS (                   -- drop baseline months
    SELECT  m.*
    FROM    month_max AS m
    JOIN    first_month AS f
      ON    m."customer_id" = f."customer_id"
    WHERE   m.year_month <> f.first_month
)

SELECT  year_month,
        SUM( COALESCE(max_30d_avg_bal,0) ) AS monthly_total_max_30d_avg_bal
FROM    exclude_baseline
GROUP   BY year_month
ORDER   BY year_month;