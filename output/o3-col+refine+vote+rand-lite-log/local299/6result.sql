WITH daily AS (               -- 1) daily net movement (+ deposits / – others)
  SELECT "customer_id",
         "txn_date",
         SUM(CASE WHEN "txn_type" = 'deposit'
                  THEN  "txn_amount"
                  ELSE -1 * "txn_amount" END) AS "daily_net"
  FROM   "customer_transactions"
  GROUP  BY "customer_id",
           "txn_date"
),

running AS (                 -- 2) running (cumulative) balance
  SELECT "customer_id",
         "txn_date",
         SUM("daily_net") OVER (
             PARTITION BY "customer_id"
             ORDER BY      "txn_date"
             ROWS BETWEEN  UNBOUNDED PRECEDING AND CURRENT ROW
         ) AS "running_balance"
  FROM   daily
),

avg30 AS (                   -- 3) 30-day rolling average (need full 30 rows; negatives → 0)
  SELECT "customer_id",
         "txn_date",
         CASE
           WHEN COUNT(*) OVER (                  -- make sure we have 30 days
                    PARTITION BY "customer_id"
                    ORDER BY      "txn_date"
                    ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
                ) = 30
           THEN
             CASE
               WHEN AVG("running_balance") OVER (
                        PARTITION BY "customer_id"
                        ORDER BY      "txn_date"
                        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
                    ) < 0
               THEN 0
               ELSE AVG("running_balance") OVER (
                        PARTITION BY "customer_id"
                        ORDER BY      "txn_date"
                        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
                    )
             END
           ELSE NULL                              -- not enough history yet
         END AS "avg_30d_balance"
  FROM   running
),

month_max AS (               -- 4) customer’s peak 30-day average inside each month
  SELECT "customer_id",
         strftime('%Y-%m', "txn_date") AS "month_year",
         MAX("avg_30d_balance")        AS "max_30d_balance_in_month"
  FROM   avg30
  GROUP  BY "customer_id",
           "month_year"
),

baseline AS (                -- 5) very first month per customer (to be excluded)
  SELECT "customer_id",
         MIN("month_year") AS "baseline_month"
  FROM   month_max
  GROUP  BY "customer_id"
)

-- 6) final monthly totals (baseline month removed)
SELECT   m."month_year",
         ROUND(SUM(m."max_30d_balance_in_month"), 4) AS "total_peak_30d_balance"
FROM     month_max  AS m
LEFT JOIN baseline  AS b
       ON b."customer_id"   = m."customer_id"
      AND b."baseline_month" = m."month_year"
WHERE    b."baseline_month" IS NULL        -- drop baseline month
GROUP BY m."month_year"
ORDER BY m."month_year";