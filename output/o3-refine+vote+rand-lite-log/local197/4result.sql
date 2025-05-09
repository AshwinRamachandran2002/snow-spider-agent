WITH top_10_customers AS (
    -- 1. Top 10 customers by total payments
    SELECT customer_id,
           SUM(amount) AS total_paid
    FROM payment
    GROUP BY customer_id
    ORDER BY total_paid DESC
    LIMIT 10
),
monthly_totals AS (
    -- 2. Monthly payment totals for those customers
    SELECT p.customer_id,
           strftime('%Y-%m', p.payment_date) AS month,
           SUM(p.amount) AS month_total
    FROM payment AS p
    JOIN top_10_customers AS t
      ON t.customer_id = p.customer_id
    GROUP BY p.customer_id, month
),
month_over_month AS (
    -- 3. Month‑over‑month absolute differences
    SELECT customer_id,
           month,
           ROUND(ABS(month_total
                 - LAG(month_total) OVER (PARTITION BY customer_id ORDER BY month)), 2) AS diff
    FROM monthly_totals
)
-- 4. Pick the largest month‑over‑month change
SELECT customer_id,
       month,
       diff AS difference
FROM month_over_month
WHERE diff IS NOT NULL
ORDER BY diff DESC
LIMIT 1;