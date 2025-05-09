WITH monthly_totals AS (
    SELECT
        p.customer_id,
        strftime('%Y-%m', p.payment_date) AS yyyymm,
        SUM(p.amount) AS month_total
    FROM payment p
    GROUP BY p.customer_id, yyyymm
),
monthly_changes AS (
    SELECT
        customer_id,
        month_total - LAG(month_total) OVER (PARTITION BY customer_id ORDER BY yyyymm) AS month_change
    FROM monthly_totals
),
avg_changes AS (
    SELECT
        customer_id,
        AVG(month_change) AS avg_month_change
    FROM monthly_changes
    WHERE month_change IS NOT NULL
    GROUP BY customer_id
),
top_customer AS (
    SELECT customer_id
    FROM avg_changes
    ORDER BY avg_month_change DESC
    LIMIT 1
)
SELECT c.first_name || ' ' || c.last_name AS full_name
FROM customer c
JOIN top_customer tc ON c.customer_id = tc.customer_id;