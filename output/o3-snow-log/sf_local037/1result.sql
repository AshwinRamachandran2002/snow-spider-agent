WITH category_payment_counts AS (
    /* count how many times each payment type is used within every product category */
    SELECT
        p."product_category_name",
        pay."payment_type",
        COUNT(*) AS "payment_cnt",
        ROW_NUMBER() OVER (
            PARTITION BY p."product_category_name"
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_ITEMS"  AS oi
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_PRODUCTS"     AS p
      ON oi."product_id" = p."product_id"
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS" AS pay
      ON oi."order_id" = pay."order_id"
    GROUP BY
        p."product_category_name",
        pay."payment_type"
),
most_common_payment_per_category AS (
    /* keep only the most-used payment type per category */
    SELECT
        "product_category_name",
        "payment_type",
        "payment_cnt"
    FROM category_payment_counts
    WHERE rn = 1
)
SELECT
    COALESCE(trans."product_category_name_english",
             m."product_category_name")        AS "product_category",
    m."payment_type",
    m."payment_cnt"
FROM most_common_payment_per_category AS m
LEFT JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."PRODUCT_CATEGORY_NAME_TRANSLATION" AS trans
  ON m."product_category_name" = trans."product_category_name"
ORDER BY
    m."payment_cnt" DESC NULLS LAST
LIMIT 3;