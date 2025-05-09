WITH RECURSIVE
/* ------------------------------------------------------------------
 1. First and last transaction dates for every customer
------------------------------------------------------------------ */
min_max AS (
  SELECT
      customer_id,
      DATE(MIN(txn_date)) AS min_date,
      DATE(MAX(txn_date)) AS max_date
  FROM   customer_transactions
  GROUP  BY customer_id
),
/* ------------------------------------------------------------------
 2. Continuous calendar series for every customer (fills missing days)
------------------------------------------------------------------ */
date_series AS (
  SELECT customer_id,
         min_date AS txn_date
  FROM   min_max
  UNION ALL
  SELECT customer_id,
         DATE(txn_date,'+1 day')
  FROM   date_series
  JOIN   min_max USING (customer_id)
  WHERE  DATE(txn_date,'+1 day') <= max_date
),
/* ------------------------------------------------------------------
 3. Net daily change (deposits add, all other types subtract)
------------------------------------------------------------------ */
agg_txn AS (
  SELECT
      customer_id,
      DATE(txn_date) AS txn_date,
      SUM(CASE WHEN txn_type = 'deposit'
               THEN  txn_amount
               ELSE -txn_amount END) AS net_change
  FROM   customer_transactions
  GROUP  BY customer_id, DATE(txn_date)
),
/* ------------------------------------------------------------------
 4. Place every customer on every calendar day
------------------------------------------------------------------ */
daily_txn AS (
  SELECT
      ds.customer_id,
      ds.txn_date,
      COALESCE(a.net_change,0) AS net_change
  FROM   date_series ds
  LEFT   JOIN agg_txn a
         ON  ds.customer_id = a.customer_id
         AND ds.txn_date    = a.txn_date
),
/* ------------------------------------------------------------------
 5. Running balance per customer
------------------------------------------------------------------ */
running_balance AS (
  SELECT
      customer_id,
      txn_date,
      SUM(net_change) OVER (PARTITION BY customer_id
                            ORDER BY txn_date) AS balance
  FROM   daily_txn
),
/* ------------------------------------------------------------------
 6. 30‑day rolling average of the running balance
------------------------------------------------------------------ */
balance_metrics AS (
  SELECT
      customer_id,
      txn_date,
      balance,
      ROW_NUMBER() OVER (PARTITION BY customer_id
                         ORDER BY txn_date)                            AS rn,
      AVG(balance) OVER (PARTITION BY customer_id
                         ORDER BY txn_date
                         ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)   AS avg30
  FROM   running_balance
),
/* ------------------------------------------------------------------
 7. Keep rows after 30 days and cap negative averages at zero
------------------------------------------------------------------ */
valid_avg AS (
  SELECT
      customer_id,
      txn_date,
      CASE 
          WHEN rn >= 30 THEN MAX(avg30,0)
      END AS avg_30_bal
  FROM   balance_metrics
  WHERE  rn >= 30
),
/* ------------------------------------------------------------------
 8. First (baseline) month for every customer
------------------------------------------------------------------ */
baseline_month AS (
  SELECT
      customer_id,
      STRFTIME('%Y-%m', MIN(txn_date)) AS base_month
  FROM   customer_transactions
  GROUP  BY customer_id
),
/* ------------------------------------------------------------------
 9. Customer‑month maximum of the 30‑day average (excluding baseline)
------------------------------------------------------------------ */
cust_monthly_max AS (
  SELECT
      v.customer_id,
      STRFTIME('%Y-%m', v.txn_date) AS month_year,
      MAX(v.avg_30_bal)             AS max_30_avg
  FROM   valid_avg v
  JOIN   baseline_month b
         ON v.customer_id = b.customer_id
  WHERE  STRFTIME('%Y-%m', v.txn_date) <> b.base_month
  GROUP  BY v.customer_id, month_year
),
/* ------------------------------------------------------------------
10. Sum maxima across all customers for every month
------------------------------------------------------------------ */
monthly_totals AS (
  SELECT
      month_year,
      ROUND(SUM(max_30_avg),4) AS total_max_30day_avg_balance
  FROM   cust_monthly_max
  GROUP  BY month_year
)
/* ------------------------------------------------------------------
11. Final output
------------------------------------------------------------------ */
SELECT
    month_year,
    total_max_30day_avg_balance
FROM monthly_totals
ORDER BY month_year;