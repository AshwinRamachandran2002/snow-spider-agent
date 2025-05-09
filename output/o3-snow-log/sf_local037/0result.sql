WITH payments_per_category AS (
    SELECT
        p."product_category_name",
        pay."payment_type",
        COUNT(*) AS "payment_count"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_ITEMS       oi
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_PRODUCTS          p
         ON oi."product_id" = p."product_id"
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_PAYMENTS    pay
         ON oi."order_id" = pay."order_id"
    GROUP BY
        p."product_category_name",
        pay."payment_type"
),
most_common_payment_type AS (
    SELECT
        "product_category_name",
        "payment_type",
        "payment_count",
        ROW_NUMBER() OVER (
            PARTITION BY "product_category_name"
            ORDER BY "payment_count" DESC
        ) AS rn
    FROM payments_per_category
)
SELECT
    "product_category_name",
    "payment_type"               AS "most_common_payment_type",
    "payment_count"              AS "payments_using_that_type"
FROM most_common_payment_type
WHERE rn = 1
ORDER BY "payment_count" DESC NULLS LAST
LIMIT 3;