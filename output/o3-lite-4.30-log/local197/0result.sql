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
        ROUND(SUM(amount), 2) AS monthly_total
    FROM payment
    WHERE customer_id IN (SELECT customer_id FROM top10)
    GROUP BY customer_id, month
),
diffs AS (
    SELECT
        customer_id,
        month,
        ABS(LEAD(monthly_total) OVER (PARTITION BY customer_id ORDER BY month) - monthly_total) AS mom_diff
    FROM monthly
)
SELECT 
    customer_id,
    month,
    ROUND(mom_diff, 2) AS max_month_over_month_difference
FROM diffs
WHERE mom_diff IS NOT NULL
ORDER BY mom_diff DESC
LIMIT 1;