WITH category_payment_counts AS (
    -- count how many times each payment type is used inside every product category
    SELECT
        pr."product_category_name",
        p."payment_type",
        COUNT(*) AS "payment_cnt"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_PAYMENTS   p
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_ITEMS      oi
      ON p."order_id" = oi."order_id"
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_PRODUCTS         pr
      ON oi."product_id" = pr."product_id"
    WHERE pr."product_category_name" IS NOT NULL
      AND p."payment_type" IS NOT NULL
    GROUP BY
        pr."product_category_name",
        p."payment_type"
),
most_common_payment_per_category AS (
    -- keep only the single most-used payment type inside each category
    SELECT
        "product_category_name",
        "payment_type",
        "payment_cnt",
        ROW_NUMBER() OVER (PARTITION BY "product_category_name"
                           ORDER BY "payment_cnt" DESC) AS "rn"
    FROM category_payment_counts
),
top_categories AS (
    SELECT
        "product_category_name",
        "payment_type",
        "payment_cnt"
    FROM most_common_payment_per_category
    WHERE "rn" = 1      -- most-used payment type per category
)
-- finally, pick the three categories whose (most-used) payment type has the highest counts
SELECT
    "product_category_name",
    "payment_type",
    "payment_cnt"
FROM top_categories
ORDER BY "payment_cnt" DESC NULLS LAST
LIMIT 3;