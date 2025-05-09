WITH payment_counts AS (
    SELECT
        op."product_category_name" AS category,
        oop."payment_type",
        COUNT(*)                  AS payments_cnt
    FROM "olist_order_payments"  AS oop
    JOIN "olist_order_items"     AS ooi ON ooi."order_id" = oop."order_id"
    JOIN "olist_products"        AS op  ON op."product_id" = ooi."product_id"
    GROUP BY op."product_category_name",
             oop."payment_type"
),
ranked AS (
    SELECT
        category,
        payment_type,
        payments_cnt,
        ROW_NUMBER() OVER (PARTITION BY category
                           ORDER BY payments_cnt DESC) AS rn
    FROM payment_counts
)
SELECT
    category,
    payment_type,
    payments_cnt
FROM ranked
WHERE rn = 1
ORDER BY payments_cnt DESC
LIMIT 3;