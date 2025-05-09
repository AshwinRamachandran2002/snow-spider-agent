WITH customer_total AS (
    -- 1. find the ten customers who have paid the most money overall
    SELECT customer_id,
           SUM(amount) AS total_paid
    FROM payment
    GROUP BY customer_id
    ORDER BY total_paid DESC
    LIMIT 10
),
monthly_totals AS (
    -- 2. monthly payment totals for those ten customers
    SELECT p.customer_id,
           strftime('%Y-%m', p.payment_date) AS month,   -- year‑month key
           SUM(p.amount) AS month_amount
    FROM payment AS p
    JOIN customer_total AS c
      ON c.customer_id = p.customer_id
    GROUP BY p.customer_id, month
),
month_diffs AS (
    -- 3. month‑over‑month absolute differences
    SELECT customer_id,
           month,
           ABS( LEAD(month_amount) OVER (PARTITION BY customer_id
                                         ORDER BY month) - month_amount ) AS diff
    FROM monthly_totals
)
-- 4. pick the greatest difference
SELECT customer_id,
       month  AS change_start_month,
       ROUND(diff, 2) AS largest_monthly_difference
FROM month_diffs
WHERE diff IS NOT NULL
ORDER BY diff DESC
LIMIT 1;