/*-----------------------------------------------------------------------
  Monthly sum of customers’ peak 30-day rolling-average balances
  (deposits +, other types –; negative averages floored to 0; each
   customer’s first calendar-month excluded from the final totals)
-----------------------------------------------------------------------*/
WITH
/* 1. Date span for every customer */
cust_dates(customer_id, min_date, max_date) AS (
  SELECT  "customer_id",
          DATE(MIN("txn_date")),
          DATE(MAX("txn_date"))
  FROM    "customer_transactions"
  GROUP BY "customer_id"
),
/* 2. Generate every calendar day within each customer’s span */
calendar(customer_id, cal_date, max_date) AS (
  SELECT customer_id, min_date, max_date
  FROM   cust_dates
  UNION ALL
  SELECT customer_id,
         DATE(cal_date,'+1 day'),
         max_date
  FROM   calendar
  WHERE  cal_date < max_date
),
/* 3. Net cash-flow for every customer-day
       (0 on days with no transactions) */
daily AS (
  SELECT  c.customer_id,
          c.cal_date                        AS txn_date,
          COALESCE(SUM(
                     CASE WHEN t.txn_type = 'deposit'
                          THEN  t.txn_amount
                          ELSE -t.txn_amount
                     END), 0)               AS net_amount
  FROM    calendar           AS c
  LEFT JOIN "customer_transactions" AS t
       ON  t.customer_id = c.customer_id
       AND DATE(t.txn_date) = c.cal_date
  GROUP  BY c.customer_id, c.cal_date
),
/* 4. End-of-day running balance + row number (to know when 30 days passed) */
balance AS (
  SELECT  customer_id,
          txn_date,
          SUM(net_amount) OVER (
              PARTITION BY customer_id
              ORDER BY     txn_date
          )                                    AS daily_balance,
          ROW_NUMBER() OVER (
              PARTITION BY customer_id
              ORDER BY     txn_date
          )                                    AS rn
  FROM    daily
),
/* 5. 30-day rolling average balance (only once 30 distinct days exist;
      floor negatives to 0) */
avg30 AS (
  SELECT  customer_id,
          txn_date,
          CASE
              WHEN rn >= 30 THEN
                   CASE
                       WHEN AVG(daily_balance) OVER (
                                PARTITION BY customer_id
                                ORDER BY     txn_date
                                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
                            ) < 0
                       THEN 0
                       ELSE AVG(daily_balance) OVER (
                                PARTITION BY customer_id
                                ORDER BY     txn_date
                                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
                            )
                   END
          END                              AS adj_avg_30_balance
  FROM    balance
),
/* 6. For each customer & month, pick the maximum 30-day average */
cust_month_max AS (
  SELECT  customer_id,
          STRFTIME('%Y-%m', txn_date)    AS month_year,
          MAX(adj_avg_30_balance)        AS max_30_balance
  FROM    avg30
  WHERE   adj_avg_30_balance IS NOT NULL
  GROUP  BY customer_id, month_year
),
/* 7. First (baseline) calendar-month for every customer */
first_month AS (
  SELECT  customer_id,
          SUBSTR(MIN(txn_date),1,7)      AS first_month
  FROM    "customer_transactions"
  GROUP  BY customer_id
)
/* 8. Final result: sum of monthly peaks, excluding baseline months */
SELECT  c.month_year,
        ROUND(SUM(c.max_30_balance), 4)  AS total_max_30_balance
FROM    cust_month_max AS c
JOIN    first_month    AS f
  ON    c.customer_id = f.customer_id
WHERE   c.month_year <> f.first_month
GROUP  BY c.month_year
ORDER BY c.month_year;