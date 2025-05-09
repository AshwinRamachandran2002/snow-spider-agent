WITH top_customers AS (
    SELECT customer_id
    FROM payment
    GROUP BY customer_id
    ORDER BY SUM(amount) DESC, customer_id
    LIMIT 10
),
monthly_totals AS (
    SELECT
        customer_id,
        strftime('%Y-%m', payment_date) AS month,
        SUM(amount) AS month_total
    FROM payment
    WHERE customer_id IN (SELECT customer_id FROM top_customers)
    GROUP BY customer_id, month
),
month_diffs AS (
    SELECT
        customer_id,
        month,                                   -- month of the later period
        ROUND(ABS(month_total 
              - LAG(month_total) OVER (PARTITION BY customer_id ORDER BY month)), 2) AS diff
    FROM monthly_totals
)
SELECT
    customer_id,
    month,
    diff
FROM month_diffs
WHERE diff IS NOT NULL
ORDER BY diff DESC
LIMIT 1;