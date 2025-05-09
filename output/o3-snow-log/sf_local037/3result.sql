/*  Top three product categories whose most-used payment type
    registers the highest number of payments overall            */

WITH category_payment_counts AS (
    SELECT
        pr."product_category_name",
        pmt."payment_type",
        COUNT(*) AS "num_payments"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS" AS pmt
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_ITEMS"    AS oi
          ON oi."order_id" = pmt."order_id"
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_PRODUCTS"       AS pr
          ON pr."product_id" = oi."product_id"
    GROUP BY
        pr."product_category_name",
        pmt."payment_type"
),

top_payment_type_per_category AS (
    SELECT
        "product_category_name",
        "payment_type",
        "num_payments",
        ROW_NUMBER() OVER (
            PARTITION BY "product_category_name"
            ORDER BY "num_payments" DESC
        ) AS rn
    FROM category_payment_counts
)

SELECT
    COALESCE(tr."product_category_name_english",
             tp."product_category_name")    AS "product_category",
    tp."payment_type",
    tp."num_payments"
FROM top_payment_type_per_category AS tp
LEFT JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."PRODUCT_CATEGORY_NAME_TRANSLATION" AS tr
       ON tr."product_category_name" = tp."product_category_name"
WHERE tp.rn = 1
ORDER BY tp."num_payments" DESC NULLS LAST
LIMIT 3;