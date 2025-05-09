WITH monthly_totals AS (
    SELECT
        customer_id,
        strftime('%Y-%m', payment_date) AS ym,
        SUM(amount) AS month_total
    FROM payment
    GROUP BY customer_id, ym
),
monthly_changes AS (
    SELECT
        customer_id,
        ym,
        ABS(month_total - LAG(month_total) OVER (PARTITION BY customer_id ORDER BY ym)) AS change_amt
    FROM monthly_totals
),
avg_changes AS (
    SELECT
        customer_id,
        AVG(change_amt) AS avg_monthly_change
    FROM monthly_changes
    WHERE change_amt IS NOT NULL
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