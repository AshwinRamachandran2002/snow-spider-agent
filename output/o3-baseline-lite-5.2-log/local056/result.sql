WITH monthly_totals AS (
    SELECT
        p.customer_id,
        strftime('%Y-%m', p.payment_date) AS year_month,
        SUM(p.amount) AS month_total
    FROM payment p
    GROUP BY p.customer_id, year_month
),
month_diffs AS (
    SELECT
        customer_id,
        ABS(month_total - LAG(month_total) OVER (
            PARTITION BY customer_id
            ORDER BY year_month
        )) AS diff_abs
    FROM monthly_totals
),
avg_changes AS (
    SELECT
        customer_id,
        AVG(diff_abs) AS avg_monthly_change
    FROM month_diffs
    WHERE diff_abs IS NOT NULL            -- need at least two months to have a change
    GROUP BY customer_id
),
top_customer AS (
    SELECT customer_id
    FROM avg_changes
    ORDER BY avg_monthly_change DESC
    LIMIT 1
)
SELECT
    c.first_name || ' ' || c.last_name AS full_name
FROM customer c
JOIN top_customer t ON c.customer_id = t.customer_id;