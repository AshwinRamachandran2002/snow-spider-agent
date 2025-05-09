WITH monthly AS (
    SELECT
        customer_id,
        strftime('%Y-%m', payment_date) AS ym,
        SUM(amount) AS total_amount
    FROM payment
    GROUP BY customer_id, ym
),
diffs AS (
    SELECT
        customer_id,
        ABS(total_amount - LAG(total_amount) OVER (
            PARTITION BY customer_id
            ORDER BY ym
        )) AS diff
    FROM monthly
),
avg_diff AS (
    SELECT
        customer_id,
        AVG(diff) AS avg_monthly_change
    FROM diffs
    WHERE diff IS NOT NULL
    GROUP BY customer_id
),
top_customer AS (
    SELECT customer_id
    FROM avg_diff
    ORDER BY avg_monthly_change DESC
    LIMIT 1
)
SELECT c.first_name || ' ' || c.last_name AS full_name
FROM customer c
JOIN top_customer t ON c.customer_id = t.customer_id;