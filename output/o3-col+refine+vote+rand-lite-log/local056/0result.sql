WITH monthly AS (
    SELECT
        customer_id,
        STRFTIME('%Y-%m', payment_date) AS ym,
        SUM(amount) AS monthly_total
    FROM payment
    GROUP BY customer_id, ym
),
changes AS (
    SELECT
        customer_id,
        monthly_total
        - LAG(monthly_total) OVER (PARTITION BY customer_id ORDER BY ym) AS delta
    FROM monthly
),
avg_change AS (
    SELECT
        customer_id,
        AVG(delta) AS avg_monthly_change
    FROM changes
    WHERE delta IS NOT NULL
    GROUP BY customer_id
),
top_cust AS (
    SELECT customer_id
    FROM avg_change
    ORDER BY avg_monthly_change DESC
    LIMIT 1
)
SELECT c.first_name || ' ' || c.last_name AS full_name
FROM customer AS c
JOIN top_cust AS t ON c.customer_id = t.customer_id;