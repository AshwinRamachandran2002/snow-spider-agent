WITH RECURSIVE
/* 1 ── daily signed movement per customer */
txn_delta AS (
    SELECT
        customer_id,
        DATE(txn_date) AS txn_date,
        CASE
            WHEN LOWER(txn_type) = 'deposit' THEN  txn_amount      /* money in  */
            ELSE                                   -txn_amount     /* money out */
        END AS delta
    FROM customer_transactions
),
/* 2 ── earliest and latest transaction date for every customer */
cust_span AS (
    SELECT
        customer_id,
        MIN(txn_date) AS min_date,
        MAX(txn_date) AS max_date
    FROM txn_delta
    GROUP BY customer_id
),
/* 3 ── build complete date calendar for every customer (recursive) */
calendar(customer_id, cal_date, max_date) AS (
      SELECT customer_id, min_date, max_date
      FROM   cust_span
      UNION ALL
      SELECT customer_id,
             DATE(cal_date,'+1 day'),
             max_date
      FROM   calendar
      WHERE  cal_date < max_date
),
/* 4 ── attach daily movement (0 when no txns on that day) */
daily_movements AS (
    SELECT
        c.customer_id,
        c.cal_date,
        IFNULL(SUM(t.delta),0) AS daily_delta
    FROM   calendar AS c
    LEFT JOIN txn_delta AS t
           ON t.customer_id = c.customer_id
          AND t.txn_date    = c.cal_date
    GROUP BY c.customer_id, c.cal_date
),
/* 5 ── cumulative balance, negative values coerced to zero */
daily_balances AS (
    SELECT
        customer_id,
        cal_date,
        CASE
            WHEN running_bal < 0 THEN 0
            ELSE running_bal
        END AS daily_balance
    FROM (
        SELECT
            customer_id,
            cal_date,
            SUM(daily_delta) OVER (
                PARTITION BY customer_id
                ORDER BY     cal_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS running_bal
        FROM daily_movements
    )
),
/* 6 ── highest daily balance each customer achieved in every month */
customer_monthly_peak AS (
    SELECT
        customer_id,
        strftime('%Y-%m', cal_date) AS month,
        MAX(daily_balance)          AS max_daily_balance
    FROM daily_balances
    GROUP BY customer_id, month
),
/* 7 ── sum of those peaks across all customers per month */
monthly_total AS (
    SELECT
        month,
        SUM(max_daily_balance) AS total_max_daily_balance
    FROM customer_monthly_peak
    GROUP BY month
)

SELECT
    month,
    total_max_daily_balance
FROM monthly_total
ORDER BY month;