WITH top10 AS (
    SELECT customer_id
    FROM payment
    GROUP BY customer_id
    ORDER BY SUM(amount) DESC
    LIMIT 10
),
monthly AS (
    SELECT 
        customer_id,
        strftime('%Y-%m', payment_date) AS month,
        SUM(amount)                    AS month_total
    FROM payment
    WHERE customer_id IN (SELECT customer_id FROM top10)
    GROUP BY customer_id, month
),
diffs AS (
    SELECT
        customer_id,
        month,
        month_total
          - LAG(month_total) OVER (PARTITION BY customer_id ORDER BY month) AS diff
    FROM monthly
)
SELECT 
    customer_id,
    month,
    ROUND(diff, 2) AS max_month_over_month_difference
FROM diffs
WHERE diff IS NOT NULL
ORDER BY ABS(diff) DESC, customer_id
LIMIT 1;