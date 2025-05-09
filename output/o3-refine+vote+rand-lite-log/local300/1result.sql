WITH
-- 1.  Net change ( + for deposits, – for withdrawals ) per customer‑day
cte_txn AS (
    SELECT
        "customer_id",
        DATE("txn_date")                        AS txn_date,
        SUM(
            CASE
                WHEN LOWER("txn_type") = 'deposit'     THEN  txn_amount
                WHEN LOWER("txn_type") = 'withdrawal'  THEN -txn_amount
                /* treat any other type as a negative cash‑out */
                ELSE                                   -txn_amount
            END
        )                                         AS net_change
    FROM customer_transactions
    GROUP BY "customer_id", DATE("txn_date")
),

-- 2.  Each customer’s first and last transaction dates
cte_bounds AS (
    SELECT
        "customer_id",
        MIN(DATE("txn_date")) AS min_date,
        MAX(DATE("txn_date")) AS max_date
    FROM customer_transactions
    GROUP BY "customer_id"
),

-- 3.  Generate one row per customer‑day between min and max dates
series(customer_id, dt, max_date) AS (
    SELECT customer_id, min_date, max_date
    FROM   cte_bounds
    UNION ALL
    SELECT customer_id,
           DATE(dt,'+1 day'),
           max_date
    FROM   series
    WHERE  DATE(dt,'+1 day') <= max_date
),

-- 4.  Recursively calculate end‑of‑day balances,
--     carrying forward previous balances and never letting them go below zero
daily(customer_id, dt, balance) AS (
    /* base day = earliest day for each customer */
    SELECT
        s.customer_id,
        s.dt,
        CASE
            WHEN COALESCE(t.net_change,0) < 0 THEN 0
            ELSE COALESCE(t.net_change,0)
        END                          AS balance
    FROM series s
    JOIN cte_bounds b
         ON b.customer_id = s.customer_id
        AND b.min_date     = s.dt
    LEFT JOIN cte_txn  t
         ON t.customer_id = s.customer_id
        AND t.txn_date    = s.dt

    UNION ALL

    /* subsequent days */
    SELECT
        s.customer_id,
        s.dt,
        CASE
            WHEN COALESCE(t.net_change,0) + d.balance < 0
                 THEN 0
            ELSE COALESCE(t.net_change,0) + d.balance
        END                     AS balance
    FROM daily  d
    JOIN series s
         ON s.customer_id = d.customer_id
        AND s.dt          = DATE(d.dt,'+1 day')
    LEFT JOIN cte_txn t
         ON t.customer_id = s.customer_id
        AND t.txn_date    = s.dt
),

-- 5.  Highest daily balance each customer hit within every month
monthly_max AS (
    SELECT
        customer_id,
        STRFTIME('%Y-%m', dt)   AS month,
        MAX(balance)            AS max_balance
    FROM daily
    GROUP BY customer_id, month
)

-- 6.  Sum those per‑customer monthly peaks to get the overall monthly total
SELECT
    month,
    SUM(max_balance)  AS monthly_total_max_balance
FROM monthly_max
GROUP BY month
ORDER BY month;