WITH monthly_totals AS (
    SELECT
        customer_id,
        strftime('%Y-%m', payment_date) AS payment_month,
        SUM(amount) AS total_payment
    FROM payment
    GROUP BY customer_id, payment_month
),
monthly_changes AS (
    SELECT
        customer_id,
        ABS(total_payment - LAG(total_payment) OVER (PARTITION BY customer_id ORDER BY payment_month)) AS change_in_payment
    FROM monthly_totals
)

SELECT 
    c.first_name || ' ' || c.last_name AS name
FROM (
    SELECT
        customer_id,
        AVG(change_in_payment) AS avg_monthly_change
    FROM monthly_changes
    WHERE change_in_payment IS NOT NULL
    GROUP BY customer_id
    ORDER BY avg_monthly_change DESC
    LIMIT 1
) mc
JOIN customer c ON mc.customer_id = c.customer_id;