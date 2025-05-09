WITH category_payment_counts AS (
    SELECT
        p.product_category_name        AS product_category_name,
        op.payment_type                AS payment_type,
        COUNT(*)                       AS payment_count
    FROM olist_order_items    AS oi
    JOIN olist_products       AS p   ON p.product_id = oi.product_id
    JOIN olist_order_payments AS op  ON op.order_id  = oi.order_id
    GROUP BY
        p.product_category_name,
        op.payment_type
),
dominant_payment_type AS (
    SELECT
        product_category_name,
        payment_type,
        payment_count,
        ROW_NUMBER() OVER (
            PARTITION BY product_category_name
            ORDER BY payment_count DESC
        ) AS rn
    FROM category_payment_counts
)
SELECT
    product_category_name,
    payment_type,
    payment_count
FROM dominant_payment_type
WHERE rn = 1                          -- keep only the dominant payment type per category
ORDER BY payment_count DESC           -- rank categories by that dominant-payment count
LIMIT 3;                              -- top-3 categories