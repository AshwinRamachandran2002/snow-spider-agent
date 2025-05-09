/* -------------------------------------------------------------
   1.  Calculate each customer’s month‑end balance for every
       month in 2020 (deposits – withdrawals).
   2.  Find the month with the most customers whose balance > 0
       and the month with the fewest.
   3.  For those two months, get the average month‑end balance
       across all customers (all rows that month).
   4.  Return both months, their averages and the difference.
---------------------------------------------------------------- */
WITH month_balance AS (           -- step 1
    SELECT
        customer_id,
        strftime('%Y-%m', txn_date) AS month_yyyy_mm,
        SUM(CASE
                WHEN txn_type = 'deposit'    THEN  txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                ELSE 0
            END) AS month_end_balance
    FROM customer_transactions
    WHERE strftime('%Y', txn_date) = '2020'
    GROUP BY customer_id,
             month_yyyy_mm
),
month_positive_counts AS (        -- number of customers > 0 each month
    SELECT
        month_yyyy_mm,
        COUNT(*) FILTER (WHERE month_end_balance > 0) AS positive_cust_cnt
    FROM month_balance
    GROUP BY month_yyyy_mm
),
max_month AS (                    -- month with highest positive‑balance count
    SELECT month_yyyy_mm
    FROM   month_positive_counts
    ORDER  BY positive_cust_cnt DESC, month_yyyy_mm       -- tie → earliest
    LIMIT  1
),
min_month AS (                    -- month with lowest positive‑balance count
    SELECT month_yyyy_mm
    FROM   month_positive_counts
    ORDER  BY positive_cust_cnt ASC,  month_yyyy_mm       -- tie → earliest
    LIMIT  1
),
avg_balances AS (                 -- step 3
    SELECT
        month_yyyy_mm,
        AVG(month_end_balance) AS avg_month_end_balance
    FROM month_balance
    GROUP BY month_yyyy_mm
),
summary AS (
    SELECT
        (SELECT month_yyyy_mm FROM max_month)       AS month_highest_pos_bal,
        (SELECT avg_month_end_balance
         FROM   avg_balances
         WHERE  month_yyyy_mm = (SELECT month_yyyy_mm FROM max_month)
        )                                           AS avg_balance_highest,
        (SELECT month_yyyy_mm FROM min_month)       AS month_lowest_pos_bal,
        (SELECT avg_month_end_balance
         FROM   avg_balances
         WHERE  month_yyyy_mm = (SELECT month_yyyy_mm FROM min_month)
        )                                           AS avg_balance_lowest
)
SELECT
    month_highest_pos_bal   AS month_with_highest_positive_customers,
    avg_balance_highest     AS average_balance_in_that_month,
    month_lowest_pos_bal    AS month_with_lowest_positive_customers,
    avg_balance_lowest      AS average_balance_in_that_month,
    avg_balance_highest - avg_balance_lowest
        AS difference_between_averages
FROM summary;