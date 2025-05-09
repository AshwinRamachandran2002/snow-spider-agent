WITH monthly AS (
    SELECT
        customer_id,
        strftime('%Y-%m', payment_date) AS ym,
        SUM(amount) AS month_amount
    FROM payment
    GROUP BY customer_id, ym
),
changes AS (
    SELECT
        customer_id,
        ym,
        month_amount,
        LAG(month_amount) OVER (PARTITION BY customer_id ORDER BY ym) AS prev_amount
    FROM monthly
),
diffs AS (
    SELECT
        customer_id,
        ABS(month_amount - prev_amount) AS diff
    FROM changes
    WHERE prev_amount IS NOT NULL
),
avg_diff AS (
    SELECT
        customer_id,
        AVG(diff) AS avg_monthly_change
    FROM diffs
    GROUP BY customer_id
),
top_cust AS (
    SELECT customer_id
    FROM avg_diff
    ORDER BY avg_monthly_change DESC
    LIMIT 1
)
SELECT c.first_name || ' ' || c.last_name AS full_name
FROM customer AS c
JOIN top_cust AS t ON c.customer_id = t.customer_id;