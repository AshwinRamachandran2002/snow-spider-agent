WITH monthly_balances AS (
    /* 1.  Month‑end balance for every customer */
    SELECT
        customer_id,
        strftime('%Y-%m', txn_date)          AS month_ym,
        SUM(
            CASE
                WHEN lower(txn_type) = 'deposit'     THEN  txn_amount        -- add deposits
                WHEN lower(txn_type) = 'withdrawal'  THEN -txn_amount        -- subtract withdrawals
                ELSE 0
            END
        )                                     AS month_end_balance
    FROM   customer_transactions
    WHERE  strftime('%Y', txn_date) = '2020'
    GROUP  BY customer_id, month_ym
),
positive_counts AS (
    /* 2.  Customers with a positive month‑end balance in each month */
    SELECT
        month_ym,
        SUM(CASE WHEN month_end_balance > 0 THEN 1 ELSE 0 END) AS positive_customer_cnt
    FROM   monthly_balances
    GROUP  BY month_ym
),
max_month AS (
    /* 3a. Month with the MOST customers having a positive balance */
    SELECT month_ym
    FROM   positive_counts
    ORDER  BY positive_customer_cnt DESC, month_ym
    LIMIT  1
),
min_month AS (
    /* 3b. Month with the FEWEST customers having a positive balance */
    SELECT month_ym
    FROM   positive_counts
    ORDER  BY positive_customer_cnt ASC, month_ym
    LIMIT  1
),
avg_high AS (
    /* 4a. Average month‑end balance in the “highest” month */
    SELECT AVG(month_end_balance) AS avg_bal_high
    FROM   monthly_balances
    WHERE  month_ym = (SELECT month_ym FROM max_month)
),
avg_low AS (
    /* 4b. Average month‑end balance in the “lowest” month */
    SELECT AVG(month_end_balance) AS avg_bal_low
    FROM   monthly_balances
    WHERE  month_ym = (SELECT month_ym FROM min_month)
)
SELECT
    (SELECT month_ym      FROM max_month)                         AS highest_positive_month,
    (SELECT month_ym      FROM min_month)                         AS lowest_positive_month,
    (SELECT avg_bal_high  FROM avg_high)                          AS avg_balance_highest_month,
    (SELECT avg_bal_low   FROM avg_low)                           AS avg_balance_lowest_month,
    (SELECT avg_bal_high  FROM avg_high) -
    (SELECT avg_bal_low   FROM avg_low)                           AS average_balance_difference;