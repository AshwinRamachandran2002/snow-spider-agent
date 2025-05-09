WITH txn_clean AS (   -- make every transaction signed (+ deposit / – everything else)
    SELECT
        customer_id,
        DATE(txn_date)              AS txn_date,
        CASE WHEN lower(txn_type) = 'deposit'
             THEN  txn_amount
             ELSE -txn_amount
        END                        AS amount
    FROM customer_transactions
),

cust_span AS (        -- first and last transaction day for every customer
    SELECT
        customer_id,
        MIN(txn_date) AS start_date,
        MAX(txn_date) AS end_date
    FROM txn_clean
    GROUP BY customer_id
),

/* ----------------------------------------------------------
   Generate one record for EVERY calendar day within each
   customer’s activity window (needed for proper 30‑day frame)
----------------------------------------------------------- */
all_dates(customer_id, txn_date) AS (
    SELECT customer_id, start_date
    FROM   cust_span
    UNION ALL
    SELECT ad.customer_id,
           DATE(ad.txn_date,'+1 day')
    FROM   all_dates  ad
    JOIN   cust_span  cs
           ON  ad.customer_id = cs.customer_id
    WHERE  DATE(ad.txn_date,'+1 day') <= cs.end_date
),

daily_amounts AS (    -- net movement on each calendar day
    SELECT
        d.customer_id,
        d.txn_date,
        COALESCE(SUM(t.amount),0) AS amount
    FROM   all_dates      d
    LEFT  JOIN txn_clean  t
           ON  t.customer_id = d.customer_id
           AND t.txn_date    = d.txn_date
    GROUP BY d.customer_id, d.txn_date
),

balances AS (         -- running (cumulative) balance per day
    SELECT
        customer_id,
        txn_date,
        SUM(amount) OVER (
            PARTITION BY customer_id
            ORDER BY     txn_date
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND CURRENT ROW) AS balance
    FROM daily_amounts
),

/* ----------------------------------------------------------
   30‑day rolling average balance.
   Only keep it when the window really contains 30 rows
   (i.e. 30 consecutive calendar days now exist).
----------------------------------------------------------- */
rolling AS (
    SELECT
        customer_id,
        txn_date,
        CASE WHEN COUNT(balance) OVER (
                    PARTITION BY customer_id
                    ORDER BY     txn_date
                    ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) = 30
             THEN AVG(balance)  OVER (
                    PARTITION BY customer_id
                    ORDER BY     txn_date
                    ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)
        END AS avg_30
    FROM balances
),

rolling_adj AS (      -- negative averages become zero
    SELECT
        customer_id,
        txn_date,
        CASE WHEN avg_30 IS NOT NULL AND avg_30 < 0
             THEN 0
             ELSE avg_30
        END AS avg_30_adj
    FROM rolling
),

cust_monthly_max AS ( -- customer’s max 30‑day avg within each month
    SELECT
        customer_id,
        strftime('%Y-%m', txn_date) AS month_year,
        MAX(avg_30_adj)            AS max_avg_30
    FROM   rolling_adj
    WHERE  avg_30_adj IS NOT NULL
    GROUP BY customer_id, month_year
),

baseline AS (         -- first (baseline) month for every customer
    SELECT
        customer_id,
        strftime('%Y-%m', MIN(txn_date)) AS baseline_month
    FROM txn_clean
    GROUP BY customer_id
),

filtered AS (         -- drop every customer’s baseline month
    SELECT  c.*
    FROM    cust_monthly_max c
    JOIN    baseline        b
        ON  c.customer_id = b.customer_id
    WHERE   c.month_year <> b.baseline_month
)

SELECT
    month_year,
    ROUND(SUM(max_avg_30),4) AS total_max_30day_avg_balance
FROM   filtered
GROUP BY month_year
ORDER BY month_year;