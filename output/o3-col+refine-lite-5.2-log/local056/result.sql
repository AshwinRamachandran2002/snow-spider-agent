WITH monthly AS (
    SELECT
        p.customer_id,
        strftime('%Y-%m', p.payment_date) AS year_month,
        SUM(p.amount)                    AS monthly_total
    FROM payment AS p
    GROUP BY p.customer_id, year_month
),
deltas AS (
    SELECT
        customer_id,
        monthly_total
            - LAG(monthly_total) OVER (PARTITION BY customer_id
                                        ORDER BY year_month) AS delta
    FROM monthly
),
avg_change AS (
    SELECT
        customer_id,
        AVG(ABS(delta)) AS avg_monthly_change
    FROM deltas
    WHERE delta IS NOT NULL
    GROUP BY customer_id
)
SELECT
    c.first_name || ' ' || c.last_name AS customer_full_name
FROM avg_change AS ac
JOIN customer  AS c  ON ac.customer_id = c.customer_id
ORDER BY ac.avg_monthly_change DESC, c.customer_id
LIMIT 1;