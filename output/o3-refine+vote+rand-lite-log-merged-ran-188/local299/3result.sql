WITH daily_net AS (           /* signed value of every customer’s transactions per day */
    SELECT
        customer_id,
        DATE(txn_date)                           AS txn_day,
        SUM( CASE
                 WHEN LOWER(txn_type) = 'deposit'
                      THEN  txn_amount           /* deposits add  */
                 ELSE -txn_amount               /* every other type subtracts */
             END )                              AS net_amount
    FROM   customer_transactions
    GROUP  BY customer_id , DATE(txn_date)
),

daily_balance AS (            /* running balance per day */
    SELECT
        customer_id,
        txn_day,
        SUM(net_amount) OVER (
            PARTITION BY customer_id
            ORDER BY      txn_day
            ROWS BETWEEN  UNBOUNDED PRECEDING AND CURRENT ROW
        )  AS balance
    FROM   daily_net
),

rolling_avg_30 AS (           /* 30‑day rolling average balance (needs 30 rows) */
    SELECT
        customer_id,
        txn_day,
        AVG(balance) OVER (
            PARTITION BY customer_id
            ORDER BY      txn_day
            ROWS BETWEEN  29 PRECEDING AND CURRENT ROW
        ) AS avg_30_bal
    FROM   daily_balance
),

rolling_nonneg AS (           /* treat negative averages as 0, drop NULLs (<30 rows) */
    SELECT
        customer_id,
        txn_day,
        CASE
            WHEN avg_30_bal IS NOT NULL AND avg_30_bal < 0 THEN 0
            ELSE avg_30_bal
        END AS avg_30_bal
    FROM rolling_avg_30
    WHERE avg_30_bal IS NOT NULL
),

first_month AS (              /* each customer’s first month (baseline) */
    SELECT
        customer_id,
        MIN( STRFTIME('%Y-%m', txn_day) ) AS first_month
    FROM   rolling_nonneg
    GROUP  BY customer_id
),

cust_month_max AS (           /* customer’s max 30‑day avg balance per month */
    SELECT
        customer_id,
        STRFTIME('%Y-%m', txn_day) AS month_year,
        MAX(avg_30_bal)            AS max_30_avg
    FROM   rolling_nonneg
    GROUP  BY customer_id , month_year
),

filtered_max AS (             /* exclude baseline month for every customer */
    SELECT cm.*
    FROM   cust_month_max cm
    JOIN   first_month fm
           ON cm.customer_id = fm.customer_id
    WHERE  cm.month_year <> fm.first_month
),

monthly_totals AS (           /* sum customers’ maxima per month */
    SELECT
        month_year,
        ROUND( SUM(max_30_avg), 4 ) AS monthly_total_max_30_avg
    FROM   filtered_max
    GROUP  BY month_year
)

SELECT month_year,
       monthly_total_max_30_avg
FROM   monthly_totals
ORDER  BY month_year;