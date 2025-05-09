WITH first_purchase AS (
    SELECT 
        customer_id,
        MIN(payment_date) AS first_purchase
    FROM payment
    GROUP BY customer_id
),
customer_ltv AS (
    SELECT
        p.customer_id,
        SUM(p.amount) AS total_ltv,
        SUM(
            CASE 
                WHEN p.payment_date <= datetime(fp.first_purchase, '+7 days') 
                THEN p.amount 
                ELSE 0 
            END
        ) AS ltv_7d,
        SUM(
            CASE 
                WHEN p.payment_date <= datetime(fp.first_purchase, '+30 days') 
                THEN p.amount 
                ELSE 0 
            END
        ) AS ltv_30d
    FROM payment AS p
    JOIN first_purchase AS fp
      ON fp.customer_id = p.customer_id
    GROUP BY p.customer_id
),
valid_customers AS (
    SELECT
        customer_id,
        total_ltv,
        ltv_7d,
        ltv_30d,
        (ltv_7d  * 100.0) / total_ltv AS pct_7d,
        (ltv_30d * 100.0) / total_ltv AS pct_30d
    FROM customer_ltv
    WHERE total_ltv > 0
)
SELECT
    ROUND(AVG(pct_7d), 4)   AS avg_pct_first_7_days,
    ROUND(AVG(pct_30d), 4)  AS avg_pct_first_30_days,
    ROUND(AVG(total_ltv), 4) AS avg_total_ltv
FROM valid_customers;