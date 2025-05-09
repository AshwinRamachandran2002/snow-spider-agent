WITH payment_counts AS (
    SELECT
        p."product_category_name",
        pay."payment_type",
        COUNT(*) AS "payment_cnt"
    FROM "olist_order_items"      AS oi
    JOIN "olist_products"         AS p   ON oi."product_id" = p."product_id"
    JOIN "olist_order_payments"   AS pay ON oi."order_id"   = pay."order_id"
    GROUP BY
        p."product_category_name",
        pay."payment_type"
),
ranked AS (
    SELECT
        pc.*,
        ROW_NUMBER() OVER (
            PARTITION BY pc."product_category_name"
            ORDER BY pc."payment_cnt" DESC
        ) AS rnk
    FROM payment_counts pc
)
SELECT
    "product_category_name",
    "payment_type" AS "most_used_payment_type",
    "payment_cnt"  AS "payments_made_with_that_type"
FROM ranked
WHERE rnk = 1
ORDER BY "payment_cnt" DESC
LIMIT 3;