WITH
/* 1.  Net change ( + for deposits, – for all other txn types ) for every customer‑day */
daily_change AS (
    SELECT
        customer_id,
        date(txn_date)                                 AS txn_date,
        SUM(CASE WHEN LOWER(txn_type)='deposit'
                 THEN  txn_amount
                 ELSE -txn_amount END)                 AS net_change
    FROM customer_transactions
    GROUP BY customer_id, date(txn_date)
),

/* 2.  First and last calendar days we must cover for every customer */
customer_range AS (
    SELECT
        customer_id,
        MIN(date(txn_date)) AS start_date,
        MAX(date(txn_date)) AS end_date
    FROM customer_transactions
    GROUP BY customer_id
),

/* 3.  Produce one row per customer per calendar day
       (recursive date generator) */
dates(customer_id, txn_date, end_date) AS (
    SELECT customer_id, start_date, end_date
    FROM   customer_range
    UNION ALL
    SELECT customer_id,
           date(txn_date,'+1 day'),
           end_date
    FROM   dates
    WHERE  date(txn_date,'+1 day') <= end_date
),

/* 4.  Running (cumulative) balance for every calendar day */
daily_balance AS (
    SELECT
        d.customer_id,
        d.txn_date,
        SUM(COALESCE(dc.net_change,0)) OVER (
            PARTITION BY d.customer_id
            ORDER BY     d.txn_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                               AS balance
    FROM   dates d
    LEFT  JOIN daily_change dc
           ON  dc.customer_id = d.customer_id
           AND dc.txn_date    = d.txn_date
),

/* 5.  30‑day rolling average of that daily balance
       – only after 30 days of history
       – negatives forced to zero                                    */
balance_30d AS (
    SELECT
        customer_id,
        txn_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY txn_date)         AS day_no,
        CASE
             WHEN AVG(balance) OVER (
                      PARTITION BY customer_id
                      ORDER BY     txn_date
                      ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
                  ) < 0
             THEN 0
             ELSE AVG(balance) OVER (
                      PARTITION BY customer_id
                      ORDER BY     txn_date
                      ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
                  )
        END                                                                    AS avg_30d
    FROM daily_balance
),

/* 6.  For each customer & month pick the maximum 30‑day average */
monthly_max AS (
    SELECT
        customer_id,
        strftime('%Y-%m',txn_date)     AS month,
        MAX(avg_30d)                   AS max_30d_avg
    FROM   balance_30d
    WHERE  day_no >= 30                         -- need full 30‑day window
    GROUP  BY customer_id, month
),

/* 7.  First (baseline) month for every customer */
baseline_month AS (
    SELECT
        customer_id,
        strftime('%Y-%m', MIN(date(txn_date)))  AS first_month
    FROM   customer_transactions
    GROUP  BY customer_id
)

/* 8.  Sum each month’s customer maxima,
       excluding every customer’s baseline month */
SELECT
    mm.month,
    ROUND(SUM(mm.max_30d_avg),4) AS total_max_30d_avg_across_customers
FROM          monthly_max    mm
JOIN          baseline_month bm  ON mm.customer_id = bm.customer_id
WHERE         mm.month <> bm.first_month
GROUP BY      mm.month
ORDER BY      mm.month;