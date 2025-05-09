WITH
/* 1. find each customer’s active date range */
min_max AS (
    SELECT
        customer_id,
        DATE(MIN(txn_date)) AS min_date,
        DATE(MAX(txn_date)) AS max_date
    FROM customer_transactions
    GROUP BY customer_id
),

/* 2. build an unbroken list of calendar days for every customer   */
dates(customer_id, d) AS (
    SELECT customer_id, min_date
    FROM   min_max
    UNION ALL
    SELECT dates.customer_id,
           DATE(dates.d,'+1 day')
    FROM   dates
           JOIN min_max USING (customer_id)
    WHERE  dates.d < min_max.max_date
),

/* 3. net cash movement per customer per day (+ for deposits, – for withdrawals) */
daily_net AS (
    SELECT
        customer_id,
        DATE(txn_date) AS d,
        SUM(CASE WHEN txn_type = 'deposit'
                 THEN  txn_amount
                 ELSE -txn_amount END) AS net_amount
    FROM customer_transactions
    GROUP BY customer_id, DATE(txn_date)
),

/* 4. make sure every calendar day has a row, using zero when no txn occurred */
daily_balances AS (
    SELECT
        dt.customer_id,
        dt.d,
        COALESCE(dn.net_amount,0) AS net_amount
    FROM   dates dt
    LEFT  JOIN daily_net dn
           ON  dn.customer_id = dt.customer_id
           AND dn.d           = dt.d
),

/* 5. running balance, converted to zero whenever it would go negative */
running_balances AS (
    SELECT
        customer_id,
        d,
        CASE WHEN running_total < 0 THEN 0
             ELSE running_total END AS balance
    FROM (
        SELECT
            customer_id,
            d,
            SUM(net_amount) OVER (
                 PARTITION BY customer_id
                 ORDER BY d
                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS running_total
        FROM daily_balances
    )
),

/* 6. each customer’s highest daily balance per month */
customer_monthly_max AS (
    SELECT
        customer_id,
        strftime('%Y-%m', d) AS month,
        MAX(balance)         AS max_daily_balance
    FROM running_balances
    GROUP BY customer_id, month
)

/* 7. monthly total of those maxima across all customers */
SELECT
    month,
    SUM(max_daily_balance) AS monthly_total_max_balance
FROM customer_monthly_max
GROUP BY month
ORDER BY month;