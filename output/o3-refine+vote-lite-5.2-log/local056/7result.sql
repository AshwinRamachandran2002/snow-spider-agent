WITH monthly_totals AS (
    SELECT
        customer_id,
        strftime('%Y-%m', payment_date) AS ym,
        SUM(amount) AS month_total
    FROM payment
    GROUP BY customer_id, ym
),
monthly_diffs AS (
    SELECT
        customer_id,
        ABS(month_total - LAG(month_total) OVER (PARTITION BY customer_id ORDER BY ym)) AS diff
    FROM monthly_totals
),
avg_diffs AS (
    SELECT
        customer_id,
        AVG(diff) AS avg_monthly_change
    FROM monthly_diffs
    WHERE diff IS NOT NULL          -- ignore first month which has no previous month to compare
    GROUP BY customer_id
),
top_customer AS (
    SELECT
        customer_id
    FROM avg_diffs
    ORDER BY avg_monthly_change DESC, customer_id
    LIMIT 1
)
SELECT
    c.first_name || ' ' || c.last_name AS full_name
FROM customer AS c
JOIN top_customer AS t
  ON c.customer_id = t.customer_id;