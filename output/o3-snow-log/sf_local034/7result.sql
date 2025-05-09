WITH "CATEGORY_PAYMENTS" AS (
    SELECT
        p."product_category_name"                       AS "category",
        pay."payment_type",
        COUNT(*)                                         AS "num_payments"
    FROM
        "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_ITEMS"      i
        JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_PRODUCTS"     p
              ON i."product_id" = p."product_id"
        JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_PAYMENTS" pay
              ON i."order_id" = pay."order_id"
    WHERE
        p."product_category_name" IS NOT NULL
    GROUP BY
        p."product_category_name",
        pay."payment_type"
),
"TOP_METHOD_PER_CATEGORY" AS (
    SELECT
        "category",
        "payment_type",
        "num_payments",
        ROW_NUMBER() OVER (PARTITION BY "category"
                           ORDER BY "num_payments" DESC NULLS LAST) AS "rn"
    FROM
        "CATEGORY_PAYMENTS"
)
SELECT
    AVG("num_payments") AS "avg_total_payments_for_most_preferred_method"
FROM
    "TOP_METHOD_PER_CATEGORY"
WHERE
    "rn" = 1;