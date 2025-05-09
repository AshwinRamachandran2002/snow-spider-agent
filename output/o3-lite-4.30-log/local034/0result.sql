WITH category_payment_counts AS (
    SELECT
        p."product_category_name" AS category,
        op."payment_type",
        COUNT(*)                  AS payment_count
    FROM "olist_order_payments" AS op
    JOIN "olist_order_items"    AS oi ON oi."order_id" = op."order_id"
    JOIN "olist_products"       AS p  ON p."product_id" = oi."product_id"
    GROUP BY p."product_category_name",
             op."payment_type"
),
preferred_payment_per_category AS (
    SELECT
        category,
        payment_count
    FROM (
        SELECT
            category,
            payment_count,
            ROW_NUMBER() OVER (
                PARTITION BY category
                ORDER BY payment_count DESC
            ) AS rn
        FROM category_payment_counts
    )
    WHERE rn = 1
)
SELECT
    ROUND(AVG(payment_count), 4) AS avg_total_payments
FROM preferred_payment_per_category;