WITH "cat_payments" AS (
    SELECT
        p."product_category_name",
        pay."payment_type",
        COUNT(*) AS "num_payments"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_ITEMS"  oi
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_PRODUCTS"     p
          ON oi."product_id" = p."product_id"
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS" pay
          ON oi."order_id" = pay."order_id"
    GROUP BY
        p."product_category_name",
        pay."payment_type"
),
"ranked" AS (
    SELECT
        cp."product_category_name",
        cp."payment_type",
        cp."num_payments",
        ROW_NUMBER() OVER (
            PARTITION BY cp."product_category_name"
            ORDER BY cp."num_payments" DESC
        ) AS "rn"
    FROM "cat_payments" cp
)
SELECT
    COALESCE(tr."product_category_name_english", r."product_category_name") AS "product_category",
    r."payment_type",
    r."num_payments"
FROM "ranked" r
LEFT JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."PRODUCT_CATEGORY_NAME_TRANSLATION" tr
       ON r."product_category_name" = tr."product_category_name"
WHERE r."rn" = 1
ORDER BY r."num_payments" DESC NULLS LAST
LIMIT 3;