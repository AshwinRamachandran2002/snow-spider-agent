WITH cat_order AS (          -- one row per order & product category
    SELECT DISTINCT
           oi."order_id",
           pr."product_category_name"
    FROM "olist_order_items"  AS oi
    JOIN "olist_products"     AS pr
         ON pr."product_id" = oi."product_id"
),
category_payments AS (       -- payments broken down by category & type
    SELECT
        co."product_category_name",
        op."payment_type",
        COUNT(*) AS payments
    FROM cat_order            AS co
    JOIN "olist_order_payments" AS op
         ON op."order_id" = co."order_id"
    GROUP BY co."product_category_name", op."payment_type"
),
dominant AS (                -- keep the most‑used payment type of each category
    SELECT
        cp."product_category_name",
        cp."payment_type"                AS most_used_payment_type,
        cp."payments",
        ROW_NUMBER() OVER (PARTITION BY cp."product_category_name"
                           ORDER BY cp."payments" DESC,
                                    cp."payment_type")         AS rn
    FROM category_payments cp
),
top3 AS (                    -- top 3 categories by size of their dominant payment type
    SELECT
        d."product_category_name",
        d."most_used_payment_type",
        d."payments"
    FROM dominant d
    WHERE d.rn = 1
    ORDER BY d."payments" DESC, d."product_category_name"
    LIMIT 3
)
SELECT
    COALESCE(t."product_category_name_english",
             top3."product_category_name")     AS category_english,
    top3."most_used_payment_type",
    top3."payments"                           AS payments_in_that_type
FROM top3
LEFT JOIN "product_category_name_translation" t
       ON t."product_category_name" = top3."product_category_name";