/*---------------------------------------------------------------
  Monthly totals of the summed, per‑customer maximum
  30‑day rolling‑average balances
  – deposits add, every other txn_type subtracts
  – negative rolling averages are clipped to zero
  – each customer’s first calendar‑month of activity is excluded
----------------------------------------------------------------*/

WITH RECURSIVE
/* 1. range of transaction dates for every customer */
cust_range AS (
    SELECT
        customer_id,
        DATE(MIN(txn_date)) AS min_date,
        DATE(MAX(txn_date)) AS max_date
    FROM   customer_transactions
    GROUP  BY customer_id
),

/* 2. build a complete calendar (row per day) for every customer */
calendar_dates(customer_id, txn_date, max_date) AS (
    SELECT  customer_id, min_date, max_date
    FROM    cust_range
    UNION ALL
    SELECT  customer_id,
            DATE(txn_date, '+1 day'),
            max_date
    FROM    calendar_dates
    WHERE   DATE(txn_date, '+1 day') <= max_date
),

/* 3. net movement for days that actually have transactions */
daily_change AS (
    SELECT
        customer_id,
        DATE(txn_date)                                    AS txn_date,
        SUM(CASE WHEN txn_type = 'deposit'
                 THEN txn_amount
                 ELSE -txn_amount END)                    AS net_change
    FROM   customer_transactions
    GROUP  BY customer_id, DATE(txn_date)
),

/* 4. join calendar to daily_change, fill gaps with 0 */
all_days AS (
    SELECT
        c.customer_id,
        c.txn_date,
        COALESCE(d.net_change, 0)                         AS net_change
    FROM   calendar_dates c
    LEFT   JOIN daily_change d
           ON  d.customer_id = c.customer_id
           AND d.txn_date   = c.txn_date
),

/* 5. running balance (cumulative sum) */
running_balance AS (
    SELECT
        customer_id,
        txn_date,
        SUM(net_change) OVER (
            PARTITION BY customer_id
            ORDER BY     txn_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                 AS balance
    FROM   all_days
),

/* 6. 30‑day rolling average of the balance */
rolling_30 AS (
    SELECT
        customer_id,
        txn_date,
        COUNT(*) OVER (
            PARTITION BY customer_id
            ORDER BY     txn_date
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        )                                                 AS day_cnt,
        AVG(balance) OVER (
            PARTITION BY customer_id
            ORDER BY     txn_date
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        )                                                 AS avg_30_raw
    FROM   running_balance
),

/* 7. keep only complete 30‑day windows and clip negatives */
rolling_30_clean AS (
    SELECT
        customer_id,
        txn_date,
        CASE
            WHEN day_cnt = 30 AND avg_30_raw < 0 THEN 0
            WHEN day_cnt = 30                     THEN avg_30_raw
        END                                                   AS avg_30
    FROM   rolling_30
    WHERE  day_cnt = 30
),

/* 8. customer’s maximum 30‑day average within each month */
monthly_customer_max AS (
    SELECT
        customer_id,
        strftime('%Y-%m', txn_date)                        AS month_yr,
        MAX(avg_30)                                        AS max_avg_30
    FROM   rolling_30_clean
    GROUP  BY customer_id, month_yr
),

/* 9. each customer’s first (baseline) month */
first_month AS (
    SELECT
        customer_id,
        strftime('%Y-%m', MIN(txn_date))                  AS first_month_yr
    FROM   customer_transactions
    GROUP  BY customer_id
),

/* 10. discard baseline month records */
filtered_max AS (
    SELECT  m.*
    FROM    monthly_customer_max m
    JOIN    first_month f
           ON m.customer_id = f.customer_id
    WHERE   m.month_yr <> f.first_month_yr
)

/* 11. final monthly totals */
SELECT
    month_yr                                           AS month,
    ROUND(SUM(max_avg_30), 4)                          AS monthly_total_max_30d_avg
FROM   filtered_max
GROUP  BY month_yr
ORDER  BY month_yr;