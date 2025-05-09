WITH category_payment_counts AS (
    SELECT
        p.product_category_name AS product_category,
        op.payment_type         AS payment_type,
        COUNT(*)                AS payments_count
    FROM olist_order_payments AS op
    JOIN olist_order_items    AS oi ON op.order_id = oi.order_id
    JOIN olist_products       AS p  ON oi.product_id = p.product_id
    GROUP BY p.product_category_name, op.payment_type
),
ranked_payment_types AS (
    SELECT
        product_category,
        payment_type,
        payments_count,
        ROW_NUMBER() OVER (
            PARTITION BY product_category
            ORDER BY payments_count DESC
        ) AS rn
    FROM category_payment_counts
)
SELECT
    product_category,
    payment_type AS most_common_payment_type,
    payments_count
FROM ranked_payment_types
WHERE rn = 1
ORDER BY payments_count DESC, product_category
LIMIT 3;