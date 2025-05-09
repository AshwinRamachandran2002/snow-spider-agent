WITH category_payment_counts AS (
    SELECT 
        p."product_category_name" AS product_category,
        pay."payment_type"        AS payment_type,
        COUNT(*)                  AS payments_count
    FROM "olist_order_items"  AS i
    JOIN "olist_products"     AS p   ON p."product_id"  = i."product_id"
    JOIN "olist_order_payments" AS pay ON pay."order_id" = i."order_id"
    GROUP BY p."product_category_name", pay."payment_type"
),
ranked AS (
    SELECT
        product_category,
        payment_type,
        payments_count,
        ROW_NUMBER() OVER (
            PARTITION BY product_category
            ORDER BY payments_count DESC, payment_type
        ) AS rn
    FROM category_payment_counts
)
SELECT
    product_category                     AS product_category,
    payment_type                         AS most_common_payment_type,
    payments_count                       AS "payments_count:int"
FROM ranked
WHERE rn = 1
ORDER BY payments_count DESC, product_category
LIMIT 3;