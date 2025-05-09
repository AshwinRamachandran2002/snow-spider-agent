SELECT c.first_name || ' ' || c.last_name AS customer_full_name
FROM customer AS c
JOIN (
    SELECT customer_id
    FROM (
        SELECT customer_id,
               AVG(ABS(monthly_diff)) AS avg_monthly_change
        FROM (
            SELECT customer_id,
                   year_month,
                   monthly_amount,
                   monthly_amount
                     - LAG(monthly_amount) OVER (PARTITION BY customer_id
                                                 ORDER BY year_month) AS monthly_diff
            FROM (
                SELECT customer_id,
                       strftime('%Y-%m', payment_date) AS year_month,
                       SUM(amount) AS monthly_amount
                FROM payment
                GROUP BY customer_id, year_month
            )
        )
        WHERE monthly_diff IS NOT NULL
        GROUP BY customer_id
        ORDER BY avg_monthly_change DESC
        LIMIT 1
    )
) AS top ON c.customer_id = top.customer_id;