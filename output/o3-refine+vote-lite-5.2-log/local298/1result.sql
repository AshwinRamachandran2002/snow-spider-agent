WITH txn_signed AS (        -- give every transaction a sign
    SELECT
        customer_id,
        DATE(txn_date)                                         AS txn_date,
        CASE 
            WHEN LOWER(txn_type) = 'deposit' THEN  txn_amount  -- positive
            ELSE                       -1 * txn_amount        -- negative for anything else
        END                                                   AS signed_amount
    FROM customer_transactions
),

/* net movement for every customer in every calendar month
   (month is represented by the 1st of that month)           */
monthly_net AS (
    SELECT
        customer_id,
        DATE(STRFTIME('%Y-%m-01', txn_date))  AS month_start,
        SUM(signed_amount)                    AS net_amount
    FROM txn_signed
    GROUP BY customer_id, month_start
),

/* running balance for each customer measured on the                                          
   first day of every month                                                                    */
customer_balances AS (
    SELECT
        customer_id,
        month_start,
        SUM(net_amount) OVER (PARTITION BY customer_id
                              ORDER BY month_start
                              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS balance
    FROM monthly_net
),

/* total balance of all customers for every month,
   forcing any negative customer balance to zero                                               */
total_balance_each_month AS (
    SELECT
        month_start,
        SUM(CASE WHEN balance < 0 THEN 0 ELSE balance END) AS total_balance
    FROM customer_balances
    GROUP BY month_start
),

/* shift the figures forward one month so that each row
   reports the previous‑month total balance                                                     */
shifted AS (
    SELECT
        DATE(month_start, '+1 month')  AS month_start,
        total_balance                  AS prev_month_total_balance
    FROM total_balance_each_month
)

SELECT
    month_start  AS month,
    prev_month_total_balance AS total_balance
FROM shifted
-- drop the very first calendar month (it has no “previous” month)
WHERE month_start > (SELECT MIN(month_start) FROM total_balance_each_month)
ORDER BY month_start;