/* ----------------------------------------------------------
   Monthly totals of the summed maximum 30-day average balance
   ( deposits = + , all other txn types = – )
   • negative 30-day averages are floored to 0
   • only dates with ≥ 30 days of history are kept
   • each customer’s first calendar-month is treated as baseline
     and removed before the final aggregation
---------------------------------------------------------- */
WITH
/* --- 1 : customer’s earliest transaction date ------------- */
first_txn_date AS (
  SELECT
    customer_id,
    MIN(date(txn_date))            AS first_date          -- keep as DATE
  FROM customer_transactions
  GROUP BY customer_id
),
/* --- 2 : daily net movement ( +deposit , –otherwise ) ----- */
daily_net AS (
  SELECT
    customer_id,
    date(txn_date)                 AS txn_date,           -- canonical DATE
    SUM(
        CASE WHEN txn_type = 'deposit'
             THEN txn_amount
             ELSE -txn_amount
        END
    )                               AS daily_net_amt
  FROM customer_transactions
  GROUP BY customer_id, date(txn_date)
),
/* --- 3 : running balance (cumulative sum per customer) ---- */
running_bal AS (
  SELECT
    dn.customer_id,
    dn.txn_date,
    SUM(dn.daily_net_amt) OVER (
      PARTITION BY dn.customer_id
      ORDER BY     dn.txn_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                               AS running_balance
  FROM daily_net AS dn
),
/* --- 4 : 30-day rolling average balance ------------------- */
avg30 AS (
  SELECT
    rb.customer_id,
    rb.txn_date,
    /* only produce an average once 30 distinct days exist     */
    CASE
      WHEN julianday(rb.txn_date) - julianday(ft.first_date) >= 29
      THEN MAX(0, (             -- floor negative averages to 0
        SELECT AVG(r2.running_balance)
        FROM   running_bal AS r2
        WHERE  r2.customer_id = rb.customer_id
          AND  r2.txn_date    BETWEEN date(rb.txn_date,'-29 day')
                                 AND     rb.txn_date
      ))
      ELSE NULL                 -- fewer than 30 days of history
    END                           AS avg_bal_30d
  FROM running_bal  AS rb
  JOIN first_txn_date AS ft
    ON rb.customer_id = ft.customer_id
),
/* --- 5 : customer-month maximum of the 30-day averages ----- */
month_max AS (
  SELECT
    customer_id,
    strftime('%Y', txn_date)       AS cal_year,
    strftime('%m', txn_date)       AS cal_month,
    MAX(avg_bal_30d)               AS max_avg_bal_in_month
  FROM avg30
  WHERE avg_bal_30d IS NOT NULL
  GROUP BY customer_id, cal_year, cal_month
),
/* --- 6 : identify each customer’s baseline month ----------- */
baseline_month AS (
  SELECT
    customer_id,
    strftime('%Y', first_date) || '-' || strftime('%m', first_date)
                                      AS base_month
  FROM first_txn_date
),
/* --- 7 : sum the monthly maxima across customers ----------- */
month_totals AS (
  SELECT
    mm.cal_year,
    mm.cal_month,
    SUM(mm.max_avg_bal_in_month)    AS sum_of_max_30d_avgs
  FROM month_max AS mm
  LEFT JOIN baseline_month AS bm
         ON  mm.customer_id = bm.customer_id
  WHERE (mm.cal_year || '-' || mm.cal_month) <> bm.base_month  -- drop baseline
  GROUP BY mm.cal_year, mm.cal_month
)
/* --- 8 : final ordered results ----------------------------- */
SELECT
  cal_year  AS year,
  cal_month AS month,
  sum_of_max_30d_avgs
FROM month_totals
ORDER BY year, month;