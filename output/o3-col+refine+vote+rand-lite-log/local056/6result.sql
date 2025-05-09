WITH monthly AS (
    SELECT 
        customer_id,
        strftime('%Y-%m', payment_date) AS month,
        SUM(amount)                    AS monthly_total
    FROM payment
    GROUP BY customer_id, month
),
changes AS (
    SELECT
        customer_id,
        monthly_total 
        - LAG(monthly_total) OVER (PARTITION BY customer_id ORDER BY month) AS monthly_change
    FROM monthly
),
avg_change AS (
    SELECT
        customer_id,
        AVG(monthly_change) AS avg_monthly_change
    FROM changes
    WHERE monthly_change IS NOT NULL
    GROUP BY customer_id
)
SELECT 
    c.first_name || ' ' || c.last_name AS full_name
FROM customer AS c
JOIN avg_change AS a
  ON c.customer_id = a.customer_id
ORDER BY a.avg_monthly_change DESC
LIMIT 1;