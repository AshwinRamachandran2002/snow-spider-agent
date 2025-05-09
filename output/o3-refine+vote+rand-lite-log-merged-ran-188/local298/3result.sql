WITH monthly_changes AS (
    SELECT
        customer_id,
        strftime('%Y-%m', txn_date) AS year_month,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount
                 ELSE -txn_amount END)            AS net_change
    FROM customer_transactions
    GROUP BY customer_id, year_month
),
running_balances AS (
    SELECT
        customer_id,
        year_month,
        SUM(net_change) OVER (PARTITION BY customer_id
                              ORDER BY year_month) AS balance_as_of_1st
    FROM monthly_changes
),
positive_balances AS (
    SELECT
        customer_id,
        year_month,
        CASE WHEN balance_as_of_1st < 0 THEN 0
             ELSE balance_as_of_1st END           AS non_negative_balance
    FROM running_balances
),
total_balances AS (
    SELECT
        year_month,
        SUM(non_negative_balance)                 AS total_balance
    FROM positive_balances
    GROUP BY year_month
),
with_prev AS (
    SELECT
        year_month                                AS month,
        LAG(total_balance) OVER (ORDER BY year_month)
                                                  AS prev_month_total_balance
    FROM total_balances
)
SELECT
    month,
    prev_month_total_balance
FROM with_prev
WHERE prev_month_total_balance IS NOT NULL   -- exclude the first calendar month
ORDER BY month;