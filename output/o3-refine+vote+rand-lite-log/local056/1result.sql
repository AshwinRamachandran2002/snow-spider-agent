WITH monthly AS (
    -- total payments per customer per month
    SELECT
        customer_id,
        strftime('%Y-%m', payment_date) AS ym,
        SUM(amount) AS month_total
    FROM payment
    GROUP BY customer_id, ym
),
diffs AS (
    -- absolute change between consecutive months
    SELECT
        customer_id,
        ABS(month_total - LAG(month_total) OVER (PARTITION BY customer_id ORDER BY ym)) AS diff
    FROM monthly
),
avg_diff AS (
    -- average monthly change for each customer
    SELECT
        customer_id,
        AVG(diff) AS avg_monthly_change
    FROM diffs
    WHERE diff IS NOT NULL       -- need at least two months to have a change
    GROUP BY customer_id
),
top_customer AS (
    -- customer with the highest average monthly change
    SELECT customer_id
    FROM avg_diff
    ORDER BY avg_monthly_change DESC, customer_id
    LIMIT 1
)
SELECT c.first_name || ' ' || c.last_name AS full_name
FROM customer c
JOIN top_customer t ON c.customer_id = t.customer_id;