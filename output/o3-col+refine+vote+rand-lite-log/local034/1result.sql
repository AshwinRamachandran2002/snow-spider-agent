WITH payment_counts AS (
    SELECT
        p.product_category_name,
        pay.payment_type,
        COUNT(*) AS num_payments,
        ROW_NUMBER() OVER (
            PARTITION BY p.product_category_name
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM olist_order_items       AS oi
    JOIN olist_products          AS p   ON p.product_id = oi.product_id
    JOIN olist_order_payments    AS pay ON pay.order_id = oi.order_id
    GROUP BY p.product_category_name,
             pay.payment_type
)
SELECT ROUND(AVG(num_payments), 4) AS avg_top_payments_per_category
FROM   payment_counts
WHERE  rn = 1;