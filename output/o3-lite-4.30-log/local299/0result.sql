WITH
cust_range AS (
    SELECT
        customer_id,
        DATE(MIN(txn_date)) AS start_date,
        DATE(MAX(txn_date)) AS end_date
    FROM customer_transactions
    GROUP BY customer_id
),
global_range AS (
    SELECT
        DATE(MIN(txn_date)) AS start_date,
        DATE(MAX(txn_date)) AS end_date
    FROM customer_transactions
),
/* build full calendar of days, then attach to every customer’s active period */
calendar AS (
    WITH RECURSIVE dates(day) AS (
        SELECT (SELECT start_date FROM global_range)
        UNION ALL
        SELECT DATE(day,'+1 day')
        FROM dates, global_range
        WHERE day < (SELECT end_date FROM global_range)
    )
    SELECT
        cr.customer_id,
        d.day
    FROM cust_range cr
    JOIN dates d
      ON d.day BETWEEN cr.start_date AND cr.end_date
),
/* aggregate daily net movement (deposit = +, all others = –) */
daily_movement AS (
    SELECT
        customer_id,
        DATE(txn_date) AS day,
        SUM(CASE WHEN txn_type = 'deposit'
                 THEN txn_amount
                 ELSE -txn_amount END) AS net
    FROM customer_transactions
    GROUP BY customer_id, DATE(txn_date)
),
/* ensure one record per customer per calendar day */
daily_balances AS (
    SELECT
        c.customer_id,
        c.day,
        COALESCE(dm.net,0) AS net
    FROM calendar c
    LEFT JOIN daily_movement dm
           ON dm.customer_id = c.customer_id
          AND dm.day         = c.day
),
/* running balance per customer per day */
running_balance AS (
    SELECT
        customer_id,
        day,
        SUM(net) OVER (PARTITION BY customer_id
                       ORDER BY day
                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_balance
    FROM daily_balances
),
/* 30‑day rolling average balance (need full 30 rows, negatives floored at 0) */
rolling_30 AS (
    SELECT
        customer_id,
        day,
        CASE
            WHEN COUNT(*) OVER (PARTITION BY customer_id
                                ORDER BY day
                                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) = 30
            THEN MAX(
                     0,
                     AVG(running_balance) OVER (PARTITION BY customer_id
                                                ORDER BY day
                                                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)
                 )
        END AS avg_30d_balance
    FROM running_balance
),
/* customer’s maximum 30‑day avg balance for every month */
cust_month_max AS (
    SELECT
        customer_id,
        SUBSTR(day,1,7)          AS month,
        MAX(avg_30d_balance)     AS max_30d_avg
    FROM rolling_30
    GROUP BY customer_id, month
),
/* first (baseline) month for every customer */
first_month AS (
    SELECT
        customer_id,
        SUBSTR(MIN(txn_date),1,7) AS first_month
    FROM customer_transactions
    GROUP BY customer_id
),
/* drop baseline month */
filtered AS (
    SELECT cmm.*
    FROM cust_month_max cmm
    LEFT JOIN first_month fm
           ON cmm.customer_id = fm.customer_id
          AND cmm.month       = fm.first_month
    WHERE fm.customer_id IS NULL
)
/* final monthly totals */
SELECT
    month,
    ROUND(SUM(max_30d_avg),4) AS total_max_30day_avg_balance
FROM filtered
GROUP BY month
ORDER BY month;