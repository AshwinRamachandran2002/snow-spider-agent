WITH txn AS (                       -- keep only 2020 and give each row a signed value
    SELECT
        customer_id,
        strftime('%Y-%m', txn_date)          AS month,
        CASE
            WHEN txn_type = 'deposit'    THEN  txn_amount
            WHEN txn_type = 'withdrawal' THEN -txn_amount
            ELSE 0
        END                                 AS signed_amount
    FROM customer_transactions
    WHERE strftime('%Y', txn_date) = '2020'
),
month_balances AS (                 -- month‑end balance for every customer & month
    SELECT
        customer_id,
        month,
        SUM(signed_amount)           AS month_end_balance
    FROM txn
    GROUP BY customer_id, month
),
positive_counts AS (                -- customers with a positive balance per month
    SELECT
        month,
        COUNT(CASE WHEN month_end_balance > 0 THEN 1 END)  AS positive_customer_cnt
    FROM month_balances
    GROUP BY month
),
high_month AS (                     -- month with the MOST positive‑balance customers
    SELECT month
    FROM positive_counts
    ORDER BY positive_customer_cnt DESC, month
    LIMIT 1
),
low_month AS (                      -- month with the FEWEST positive‑balance customers
    SELECT month
    FROM positive_counts
    ORDER BY positive_customer_cnt ASC, month
    LIMIT 1
),
avg_high AS (                       -- average balance for the “highest” month
    SELECT
        'highest_month'             AS metric,
        mb.month                    AS month,
        AVG(mb.month_end_balance)   AS average_month_end_balance
    FROM month_balances AS mb
    JOIN high_month  AS hm  ON mb.month = hm.month
    GROUP BY mb.month
),
avg_low AS (                        -- average balance for the “lowest” month
    SELECT
        'lowest_month'              AS metric,
        mb.month                    AS month,
        AVG(mb.month_end_balance)   AS average_month_end_balance
    FROM month_balances AS mb
    JOIN low_month   AS lm  ON mb.month = lm.month
    GROUP BY mb.month
),
difference AS (                     -- difference between the two averages
    SELECT
        'difference'                AS metric,
        NULL                        AS month,
        (SELECT average_month_end_balance FROM avg_high)
      - (SELECT average_month_end_balance FROM avg_low)    AS average_month_end_balance
)
SELECT
    metric,
    month,
    ROUND(average_month_end_balance, 4)  AS average_month_end_balance
FROM (
    SELECT * FROM avg_high
    UNION ALL
    SELECT * FROM avg_low
    UNION ALL
    SELECT * FROM difference
);