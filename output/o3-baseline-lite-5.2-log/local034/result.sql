WITH category_payment_counts AS (
    SELECT
        p.product_category_name                         AS category,
        op.payment_type,
        COUNT(*)                                         AS num_payments
    FROM olist_order_items            oi
    JOIN olist_products               p   ON p.product_id = oi.product_id
    JOIN olist_order_payments         op  ON op.order_id = oi.order_id
    WHERE p.product_category_name IS NOT NULL
    GROUP BY
        p.product_category_name,
        op.payment_type
),
preferred_method_per_category AS (
    SELECT
        category,
        payment_type,
        num_payments
    FROM (
        SELECT
            category,
            payment_type,
            num_payments,
            ROW_NUMBER() OVER (PARTITION BY category
                               ORDER BY num_payments DESC, payment_type) AS rn
        FROM category_payment_counts
    )
    WHERE rn = 1
)
SELECT
    AVG(num_payments) AS average_num_payments_most_preferred_method
FROM preferred_method_per_category;