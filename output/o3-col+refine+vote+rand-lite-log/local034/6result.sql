WITH category_payment_counts AS (
    SELECT
        p.product_category_name,
        op.payment_type,
        COUNT(*) AS payments_cnt
    FROM olist_order_payments AS op
    JOIN olist_order_items  AS oi ON oi.order_id  = op.order_id
    JOIN olist_products     AS p  ON p.product_id = oi.product_id
    GROUP BY p.product_category_name,
             op.payment_type
),
preferred_method_counts AS (
    SELECT
        product_category_name,
        MAX(payments_cnt) AS preferred_method_payments
    FROM category_payment_counts
    GROUP BY product_category_name
)
SELECT
    ROUND(AVG(preferred_method_payments), 4) AS avg_payments_for_preferred_method
FROM preferred_method_counts;