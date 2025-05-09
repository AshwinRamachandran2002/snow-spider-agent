WITH
daily_net AS (
    SELECT
        customer_id,
        txn_date,
        SUM(
            CASE
                WHEN txn_type = 'deposit'    THEN  txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                ELSE 0
            END
        ) AS net_change
    FROM customer_transactions
    GROUP BY customer_id, txn_date
),
span AS (
    SELECT
        customer_id,
        MIN(txn_date) AS start_d,
        MAX(txn_date) AS end_d
    FROM daily_net
    GROUP BY customer_id
),
calendar AS (
    SELECT
        customer_id,
        start_d AS cal_date,
        end_d
    FROM span
    UNION ALL
    SELECT
        customer_id,
        DATE(cal_date,'+1 day'),
        end_d
    FROM calendar
    WHERE cal_date < end_d
),
series AS (
    SELECT
        c.customer_id,
        c.cal_date,
        COALESCE(dn.net_change,0) AS net_change
    FROM   calendar  AS c
    LEFT  JOIN daily_net AS dn
           ON dn.customer_id = c.customer_id
          AND dn.txn_date    = c.cal_date
),
balances AS (
    SELECT
        customer_id,
        cal_date,
        MAX(0,
            SUM(net_change) OVER (
                PARTITION BY customer_id
                ORDER BY cal_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )
        ) AS daily_balance
    FROM series
),
cust_month_max AS (
    SELECT
        customer_id,
        STRFTIME('%Y-%m', cal_date) AS month,
        MAX(daily_balance)          AS max_daily_balance
    FROM balances
    GROUP BY customer_id, month
)
SELECT
    month,
    ROUND(SUM(max_daily_balance), 4) AS total_max_daily_balance
FROM cust_month_max
GROUP BY month
ORDER BY month;