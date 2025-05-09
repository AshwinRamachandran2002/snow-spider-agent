WITH first_payment AS (
    SELECT 
        customer_id,
        MIN(payment_date) AS first_payment_date
    FROM payment
    GROUP BY customer_id
),
customer_ltv AS (
    SELECT 
        p.customer_id,
        SUM(p.amount)                                                   AS ltv_total,
        SUM(CASE 
                WHEN p.payment_date <= datetime(fp.first_payment_date, '+7 days') 
                THEN p.amount ELSE 0 
            END)                                                       AS ltv_7,
        SUM(CASE 
                WHEN p.payment_date <= datetime(fp.first_payment_date, '+30 days') 
                THEN p.amount ELSE 0 
            END)                                                       AS ltv_30
    FROM payment AS p
    JOIN first_payment AS fp 
      ON p.customer_id = fp.customer_id
    GROUP BY p.customer_id
    HAVING ltv_total > 0              -- exclude customers with zero lifetime sales
),
customer_pct AS (
    SELECT
        customer_id,
        ltv_total,
        (ltv_7  * 100.0) / ltv_total  AS pct_7,
        (ltv_30 * 100.0) / ltv_total  AS pct_30
    FROM customer_ltv
)
SELECT 
    ROUND(AVG(pct_7), 4)   AS avg_pct_first_7_days,
    ROUND(AVG(pct_30), 4)  AS avg_pct_first_30_days,
    ROUND(AVG(ltv_total), 4) AS avg_total_ltv
FROM customer_pct;