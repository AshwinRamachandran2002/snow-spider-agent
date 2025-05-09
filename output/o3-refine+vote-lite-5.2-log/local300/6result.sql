/*----------------------------------------------------------
  1.  Get every customer’s first and last transaction dates
----------------------------------------------------------*/
WITH cust_date_range AS (
  SELECT  customer_id,
          DATE(MIN(txn_date)) AS min_date,
          DATE(MAX(txn_date)) AS max_date
  FROM    customer_transactions
  GROUP BY customer_id
),

/*----------------------------------------------------------
  2.  Build a calendar of every day for every customer
----------------------------------------------------------*/
recursive_dates AS (
  SELECT  customer_id,
          min_date AS cal_date,
          max_date
  FROM    cust_date_range
  UNION ALL
  SELECT  customer_id,
          DATE(cal_date,'+1 day'),
          max_date
  FROM    recursive_dates
  WHERE   DATE(cal_date) < max_date
),

/*----------------------------------------------------------
  3.  Net‑off each day’s transactions (+deposit, –others)
----------------------------------------------------------*/
daily_txn AS (
  SELECT  customer_id,
          DATE(txn_date)                AS txn_date,
          SUM(CASE WHEN txn_type='deposit' 
                   THEN txn_amount 
                   ELSE -txn_amount 
              END)                     AS net_amt
  FROM    customer_transactions
  GROUP BY customer_id, DATE(txn_date)
),

/*----------------------------------------------------------
  4.  Attach the transaction amounts to the calendar
      (missing days get 0)
----------------------------------------------------------*/
calendar_with_txn AS (
  SELECT  r.customer_id,
          r.cal_date                    AS txn_date,
          COALESCE(d.net_amt,0)         AS net_amt
  FROM    recursive_dates  r
  LEFT JOIN daily_txn      d
         ON r.customer_id = d.customer_id
        AND r.cal_date    = d.txn_date
),

/*----------------------------------------------------------
  5.  Running balance per customer (negatives forced to 0)
----------------------------------------------------------*/
daily_balances AS (
  SELECT  customer_id,
          txn_date,
          MAX(
                0,
                SUM(net_amt) OVER (
                    PARTITION BY customer_id
                    ORDER BY      txn_date
                    ROWS BETWEEN UNBOUNDED PRECEDING
                             AND CURRENT ROW)
          )                             AS daily_balance
  FROM    calendar_with_txn
),

/*----------------------------------------------------------
  6.  Each customer’s highest daily balance per month
----------------------------------------------------------*/
cust_monthly_max AS (
  SELECT  customer_id,
          STRFTIME('%Y-%m',txn_date)    AS month_yr,
          MAX(daily_balance)            AS max_daily_balance
  FROM    daily_balances
  GROUP BY customer_id,
           month_yr
)

/*----------------------------------------------------------
  7.  Monthly sum of those maxima across all customers
----------------------------------------------------------*/
SELECT  month_yr                      AS month,
        SUM(max_daily_balance)        AS total_max_daily_balance
FROM    cust_monthly_max
GROUP BY month_yr
ORDER BY month_yr;