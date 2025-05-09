WITH
/* 1.  Re-express each transaction as a signed cash-flow (+ deposit, – otherwise) */
trans AS (
    SELECT  customer_id,
            DATE(txn_date)                         AS txn_day,
            CASE WHEN txn_type = 'deposit'
                 THEN  txn_amount
                 ELSE -1 * txn_amount
            END                                    AS change_amt
    FROM    customer_transactions
),

/* 2.  Earliest and latest transaction dates for every customer           */
span AS (
    SELECT  customer_id,
            MIN(txn_day)  AS min_day,
            MAX(txn_day)  AS max_day
    FROM    trans
    GROUP BY customer_id
),

/* 3.  Build a complete calendar (one row per customer-day) by recursion   */
dates AS (
    /* anchor row = each customer’s first trading day */
    SELECT  customer_id,
            min_day       AS cal_day,
            max_day
    FROM    span
    UNION ALL
    /* recursively add one day until the customer’s last trading day */
    SELECT  customer_id,
            DATE(cal_day,'+1 day'),
            max_day
    FROM    dates
    WHERE   cal_day < max_day
),

/* 4.  Net cash-flow on the days where a customer actually transacted      */
day_change AS (
    SELECT  customer_id,
            txn_day,
            SUM(change_amt) AS net_change
    FROM    trans
    GROUP BY customer_id, txn_day
),

/* 5.  Running balance per customer-day, negatives floored to zero         */
running AS (
    SELECT  d.customer_id,
            d.cal_day,
            /* cumulative sum of daily net changes */
            SUM(COALESCE(dc.net_change,0))
                 OVER (PARTITION BY d.customer_id
                       ORDER BY d.cal_day
                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
                 AS running_bal
    FROM    dates       AS d
    LEFT JOIN day_change AS dc
           ON dc.customer_id = d.customer_id
          AND dc.txn_day     = d.cal_day
),
daily_bal AS (
    SELECT  customer_id,
            cal_day,
            CASE WHEN running_bal < 0 THEN 0 ELSE running_bal END AS balance
    FROM    running
),

/* 6.  Highest daily balance each customer achieved in every month         */
cust_month_max AS (
    SELECT  customer_id,
            STRFTIME('%Y-%m', cal_day)           AS month,
            MAX(balance)                         AS max_balance_in_month
    FROM    daily_bal
    GROUP BY customer_id, month
)

/* 7.  Sum those maxima across all customers to obtain the monthly total   */
SELECT      month,
            SUM(max_balance_in_month) AS total_of_monthly_max_balances
FROM        cust_month_max
GROUP BY    month
ORDER BY    month;