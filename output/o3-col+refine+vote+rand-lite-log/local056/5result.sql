WITH monthly_totals AS (
    SELECT
        customer_id,
        strftime('%Y-%m', payment_date) AS yr_month,
        SUM(amount) AS monthly_total
    FROM payment
    GROUP BY customer_id, yr_month
),
monthly_diffs AS (
    SELECT
        customer_id,
        ABS(monthly_total - LAG(monthly_total) OVER (
            PARTITION BY customer_id
            ORDER BY yr_month
        )) AS month_diff
    FROM monthly_totals
),
avg_changes AS (
    SELECT
        customer_id,
        AVG(month_diff) AS avg_monthly_change
    FROM monthly_diffs
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
FROM top_customer tc
JOIN customer c ON c.customer_id = tc.customer_id;