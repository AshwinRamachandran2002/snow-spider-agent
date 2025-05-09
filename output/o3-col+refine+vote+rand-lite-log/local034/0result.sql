WITH payments_per_category AS (
    SELECT
        p.product_category_name,
        op.payment_type,
        COUNT(*) AS num_payments
    FROM olist_order_items AS oi
    JOIN olist_products      AS p  ON p.product_id = oi.product_id
    JOIN olist_order_payments AS op ON op.order_id = oi.order_id
    GROUP BY p.product_category_name, op.payment_type
),
preferred_method AS (
    SELECT
        product_category_name,
        num_payments
    FROM (
        SELECT
            product_category_name,
            payment_type,
            num_payments,
            ROW_NUMBER() OVER (
                PARTITION BY product_category_name
                ORDER BY num_payments DESC
            ) AS rn
        FROM payments_per_category
    )
    WHERE rn = 1
)
SELECT ROUND(AVG(num_payments), 4) AS avg_preferred_payments
FROM preferred_method;