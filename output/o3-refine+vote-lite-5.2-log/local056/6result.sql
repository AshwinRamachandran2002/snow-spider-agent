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
        month_total,
        LAG(month_total) OVER (PARTITION BY customer_id ORDER BY ym) AS prev_month_total
    FROM monthly_totals
),
avg_monthly_change AS (
    SELECT
        customer_id,
        AVG(ABS(month_total - prev_month_total)) AS avg_change
    FROM monthly_changes
    WHERE prev_month_total IS NOT NULL          -- skip first month per customer
    GROUP BY customer_id
),
top_customer AS (
    SELECT customer_id
    FROM avg_monthly_change
    ORDER BY avg_change DESC, customer_id
    LIMIT 1
)
SELECT 
    c.first_name || ' ' || c.last_name AS full_name
FROM customer AS c
JOIN top_customer AS t
  ON c.customer_id = t.customer_id;