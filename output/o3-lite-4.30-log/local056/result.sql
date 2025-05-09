WITH monthly AS (
    SELECT
        customer_id,
        strftime('%Y-%m', payment_date) AS year_month,
        SUM(amount)                     AS month_total
    FROM payment
    GROUP BY customer_id, year_month
),
diffs AS (
    SELECT
        customer_id,
        month_total
          - LAG(month_total) OVER (PARTITION BY customer_id ORDER BY year_month) AS diff_amt
    FROM monthly
),
avg_change AS (
    SELECT
        customer_id,
        AVG(ABS(diff_amt)) AS avg_monthly_change
    FROM diffs
    WHERE diff_amt IS NOT NULL
    GROUP BY customer_id
)
SELECT
    c.first_name || ' ' || c.last_name AS customer_full_name
FROM avg_change ac
JOIN customer c ON c.customer_id = ac.customer_id
ORDER BY ac.avg_monthly_change DESC, c.customer_id
LIMIT 1;