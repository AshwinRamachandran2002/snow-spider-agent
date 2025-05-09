WITH
/*-----------------------------------------------
1.  Net movement for every customer‑date that has
    at least one transaction
------------------------------------------------*/
daily_net AS (
    SELECT
        customer_id,
        DATE(txn_date)                                                     AS txn_date,
        SUM(CASE WHEN LOWER(txn_type) = 'deposit' 
                 THEN  txn_amount                  /* deposits add       */
                 ELSE -1 * txn_amount              /* everything else subtracts */
            END)                                                         AS net_amount
    FROM   customer_transactions
    GROUP  BY customer_id,
              DATE(txn_date)
),

/*-----------------------------------------------
2.  Determine each customer’s first and last
    transaction dates so we can build a full
    calendar (needed to keep the running balance
    for “quiet” days with no activity)
------------------------------------------------*/
cust_bounds AS (
    SELECT
        customer_id,
        DATE( MIN(txn_date) )  AS start_date,
        DATE( MAX(txn_date) )  AS end_date
    FROM   customer_transactions
    GROUP  BY customer_id
),

/*-----------------------------------------------
3.  Build a continuous list of calendar days
    for every customer (recursive CTE)
------------------------------------------------*/
calendar(customer_id, txn_date, end_date) AS (
    SELECT customer_id,
           start_date,
           end_date
    FROM   cust_bounds
    UNION ALL
    SELECT customer_id,
           DATE(txn_date, '+1 day'),
           end_date
    FROM   calendar
    WHERE  DATE(txn_date, '+1 day') <= end_date
),

/*-----------------------------------------------
4.  Merge calendar with the daily net movement,
    inserting 0 when there were no transactions
------------------------------------------------*/
daily_net_full AS (
    SELECT
        cal.customer_id,
        cal.txn_date,
        COALESCE(dn.net_amount, 0) AS net_amount
    FROM   calendar  cal
    LEFT JOIN daily_net dn
           ON  dn.customer_id = cal.customer_id
           AND dn.txn_date    = cal.txn_date
),

/*-----------------------------------------------
5.  Running (end‑of‑day) balance
------------------------------------------------*/
daily_balance AS (
    SELECT
        customer_id,
        txn_date,
        SUM(net_amount) OVER (
              PARTITION BY customer_id
              ORDER BY     txn_date
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS balance
    FROM   daily_net_full
),

/*-----------------------------------------------
6.  30‑day rolling average balance
    • need a full 30‑calendar‑day span
    • negative averages are forced to 0
------------------------------------------------*/
rolling_30day AS (
    SELECT
        customer_id,
        txn_date,
        CASE
            /* do we have 30 calendar days in the window? */
            WHEN julianday(txn_date) - julianday(
                     MIN(txn_date) OVER (
                         PARTITION BY customer_id
                         ORDER BY     txn_date
                         ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
                     )
                 ) >= 29
            THEN
                -- average of the 30‑day window (never below zero)
                MAX(
                    0,
                    AVG(balance) OVER (
                        PARTITION BY customer_id
                        ORDER BY     txn_date
                        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
                    )
                )
        END AS avg_30day_bal
    FROM daily_balance
),

/*-----------------------------------------------
7.  First (baseline) month for every customer
------------------------------------------------*/
first_month AS (
    SELECT
        customer_id,
        STRFTIME('%Y-%m', MIN(txn_date)) AS first_month
    FROM   daily_balance
    GROUP  BY customer_id
),

/*-----------------------------------------------
8.  Maximum 30‑day average balance per customer
    per calendar month
------------------------------------------------*/
cust_monthly_max AS (
    SELECT
        customer_id,
        STRFTIME('%Y-%m', txn_date)      AS month,
        MAX(avg_30day_bal)               AS max_avg_30day_bal
    FROM   rolling_30day
    WHERE  avg_30day_bal IS NOT NULL
    GROUP  BY customer_id, month
),

/*-----------------------------------------------
9.  Exclude every customer’s baseline month
------------------------------------------------*/
cust_monthly_max_excl_base AS (
    SELECT cm.*
    FROM   cust_monthly_max cm
    JOIN   first_month      fm
           ON  cm.customer_id = fm.customer_id
    WHERE  cm.month <> fm.first_month
)

/*-----------------------------------------------
10. Final answer – sum of the monthly maxima
    across all customers
------------------------------------------------*/
SELECT
    month,
    ROUND(SUM(max_avg_30day_bal), 4) AS total_max_30day_avg_balance
FROM   cust_monthly_max_excl_base
GROUP  BY month
ORDER  BY month;