WITH month_balances AS (          -- balance for every customer & month
    SELECT
        customer_id,
        strftime('%Y-%m', txn_date)        AS month_ym,
        SUM(CASE 
                WHEN txn_type = 'deposit'    THEN  txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                ELSE 0
            END)                           AS month_end_balance
    FROM customer_transactions
    WHERE strftime('%Y', txn_date) = '2020'
    GROUP BY customer_id, month_ym
),

pos_counts AS (                   -- how many customers ended the month positive
    SELECT
        month_ym,
        SUM(CASE WHEN month_end_balance > 0 THEN 1 ELSE 0 END) AS positive_customer_cnt
    FROM month_balances
    GROUP BY month_ym
),

max_month AS (                    -- month with the most positive‑balance customers
    SELECT month_ym
    FROM   pos_counts
    ORDER  BY positive_customer_cnt DESC, month_ym
    LIMIT  1
),

min_month AS (                    -- month with the fewest positive‑balance customers
    SELECT month_ym
    FROM   pos_counts
    ORDER  BY positive_customer_cnt ASC, month_ym
    LIMIT  1
),

avg_max AS (                      -- average balance in the “max” month
    SELECT
        'highest' AS tag,
        m.month_ym,
        AVG(b.month_end_balance)  AS avg_balance
    FROM   max_month m
    JOIN   month_balances b ON b.month_ym = m.month_ym
),

avg_min AS (                      -- average balance in the “min” month
    SELECT
        'lowest' AS tag,
        m.month_ym,
        AVG(b.month_end_balance)  AS avg_balance
    FROM   min_month m
    JOIN   month_balances b ON b.month_ym = m.month_ym
),

averages AS (
    SELECT * FROM avg_max
    UNION ALL
    SELECT * FROM avg_min
)

SELECT
    (SELECT month_ym   FROM averages WHERE tag = 'highest')                 AS highest_month,
    ROUND((SELECT avg_balance FROM averages WHERE tag = 'highest'), 4)      AS highest_month_avg_balance,
    (SELECT month_ym   FROM averages WHERE tag = 'lowest')                  AS lowest_month,
    ROUND((SELECT avg_balance FROM averages WHERE tag = 'lowest'), 4)       AS lowest_month_avg_balance,
    ROUND( (SELECT avg_balance FROM averages WHERE tag = 'highest')
         - (SELECT avg_balance FROM averages WHERE tag = 'lowest'), 4)      AS difference_between_averages;