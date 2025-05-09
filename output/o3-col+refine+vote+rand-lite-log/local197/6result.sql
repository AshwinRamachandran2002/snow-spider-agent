WITH top10 AS (          -- 1. ten customers who have paid the most in total
    SELECT customer_id
    FROM (
        SELECT customer_id,
               SUM(amount) AS total_paid
        FROM   payment
        GROUP  BY customer_id
        ORDER  BY total_paid DESC
        LIMIT 10
    )
),
monthly AS (             -- 2. each top customer's total per calendar month
    SELECT p.customer_id,
           strftime('%Y-%m', p.payment_date) AS ym,
           SUM(p.amount)                     AS month_sum
    FROM   payment p
    JOIN   top10   t ON t.customer_id = p.customer_id
    GROUP  BY p.customer_id, ym
),
diffs AS (               -- 3. month-over-month differences
    SELECT customer_id,
           ym,
           month_sum
                 - LAG(month_sum) OVER (PARTITION BY customer_id
                                         ORDER BY ym)       AS mo_diff
    FROM   monthly
),
maxdiff AS (             -- 4. largest absolute change among the top-10
    SELECT customer_id,
           ym  AS month_with_max_change,
           ROUND(mo_diff, 2) AS difference
    FROM   diffs
    WHERE  mo_diff IS NOT NULL
    ORDER  BY ABS(mo_diff) DESC
    LIMIT 1
)
SELECT c.first_name || ' ' || c.last_name AS customer_name,
       m.month_with_max_change,
       m.difference
FROM   maxdiff m
JOIN   customer c USING (customer_id);