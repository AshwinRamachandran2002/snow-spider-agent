WITH category_payment_counts AS (
    SELECT
        COALESCE(t."product_category_name_english",
                 p."product_category_name") AS category,
        op."payment_type",
        COUNT(*) AS payment_count
    FROM "olist_order_items"            oi
    JOIN "olist_order_payments"         op ON op."order_id" = oi."order_id"
    JOIN "olist_products"               p  ON p."product_id" = oi."product_id"
    LEFT JOIN "product_category_name_translation" t
           ON t."product_category_name" = p."product_category_name"
    GROUP BY category, op."payment_type"
),
ranked AS (
    SELECT
        category,
        payment_type,
        payment_count,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY payment_count DESC, payment_type
        ) AS rn
    FROM category_payment_counts
)
SELECT
    category,
    payment_count
FROM ranked
WHERE rn = 1                -- most common payment_type in each category
ORDER BY payment_count DESC, category
LIMIT 3;