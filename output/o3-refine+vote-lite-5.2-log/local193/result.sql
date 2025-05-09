WITH first_purchase AS (          -- 1. first payment moment for every customer
    SELECT 
        customer_id,
        MIN(payment_date) AS first_purchase_date
    FROM payment
    GROUP BY customer_id
),
customer_ltv AS (                 -- 2. build each customer’s lifetime figures
    SELECT
        p.customer_id,
        SUM(p.amount)                                                     AS ltv_total,
        SUM(
            CASE 
                WHEN p.payment_date <= datetime(fp.first_purchase_date, '+7 days')
                THEN p.amount ELSE 0 END)                                 AS ltv_7_days,
        SUM(
            CASE 
                WHEN p.payment_date <= datetime(fp.first_purchase_date, '+30 days')
                THEN p.amount ELSE 0 END)                                 AS ltv_30_days
    FROM payment AS p
    JOIN first_purchase AS fp
          ON p.customer_id = fp.customer_id
    GROUP BY p.customer_id
    HAVING ltv_total > 0                 -- exclude customers with zero lifetime sales
),
ratios AS (                        -- 3. convert to percentages per customer
    SELECT
        customer_id,
        ltv_total,
        (ltv_7_days  * 100.0) / ltv_total AS pct_7_days,
        (ltv_30_days * 100.0) / ltv_total AS pct_30_days
    FROM customer_ltv
)
-- 4. final averages across all qualifying customers
SELECT
    ROUND(AVG(pct_7_days), 4)   AS avg_pct_first_7_days,
    ROUND(AVG(pct_30_days), 4)  AS avg_pct_first_30_days,
    ROUND(AVG(ltv_total), 4)    AS avg_total_ltv
FROM ratios;