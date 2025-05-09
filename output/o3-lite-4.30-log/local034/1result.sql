WITH payment_counts AS (
    SELECT
        p."product_category_name"      AS category,
        op."payment_type",
        COUNT(*)                       AS num_payments,
        ROW_NUMBER() OVER (
            PARTITION BY p."product_category_name"
            ORDER BY COUNT(*) DESC, op."payment_type"
        )                              AS rn
    FROM "olist_order_payments"  op
    JOIN "olist_order_items"     oi ON oi."order_id"  = op."order_id"
    JOIN "olist_products"        p  ON p."product_id" = oi."product_id"
    GROUP BY p."product_category_name", op."payment_type"
),
preferred_method AS (
    SELECT
        category,
        num_payments
    FROM payment_counts
    WHERE rn = 1        -- retain only the single most‑preferred method per category
)
SELECT
    ROUND(AVG(num_payments), 4) AS avg_total_payments
FROM preferred_method;