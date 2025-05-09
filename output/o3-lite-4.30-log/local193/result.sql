WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(payment_date) AS first_payment,
        SUM(amount)       AS total_ltv
    FROM payment
    GROUP BY customer_id
    HAVING SUM(amount) > 0                 -- exclude zero‑LTV customers
),
window_sales AS (
    SELECT
        p.customer_id,
        SUM(CASE WHEN p.payment_date <= DATETIME(fp.first_payment,'+7 days')
                 THEN p.amount END)  AS ltv_7d,
        SUM(CASE WHEN p.payment_date <= DATETIME(fp.first_payment,'+30 days')
                 THEN p.amount END) AS ltv_30d
    FROM payment p
    JOIN first_purchase fp ON p.customer_id = fp.customer_id
    GROUP BY p.customer_id
)
SELECT
    ROUND(AVG(fp.total_ltv), 4)                           AS average_total_lifetime_sales,
    ROUND(AVG(ws.ltv_7d  * 1.0 / fp.total_ltv) * 100, 4)  AS pct_ltv_first_7_days,
    ROUND(AVG(ws.ltv_30d * 1.0 / fp.total_ltv) * 100, 4)  AS pct_ltv_first_30_days
FROM window_sales ws
JOIN first_purchase fp ON ws.customer_id = fp.customer_id;