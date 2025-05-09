WITH first_dt AS (
    SELECT
        customer_id,
        MIN(payment_date) AS first_purchase
    FROM payment
    GROUP BY customer_id
),
calc AS (
    SELECT
        p.customer_id,
        SUM(p.amount) AS total_ltv,
        SUM(
            CASE
                WHEN (strftime('%s', p.payment_date) - strftime('%s', f.first_purchase)) < 604800
                THEN p.amount ELSE 0
            END
        ) AS amt_7d,
        SUM(
            CASE
                WHEN (strftime('%s', p.payment_date) - strftime('%s', f.first_purchase)) < 2592000
                THEN p.amount ELSE 0
            END
        ) AS amt_30d
    FROM payment AS p
    JOIN first_dt AS f USING (customer_id)
    GROUP BY p.customer_id
)
SELECT
    ROUND(AVG(total_ltv), 4)                    AS avg_ltv,
    ROUND(AVG(100.0 * amt_7d  / total_ltv), 4) AS avg_pct_7d,
    ROUND(AVG(100.0 * amt_30d / total_ltv), 4) AS avg_pct_30d
FROM calc
WHERE total_ltv > 0;