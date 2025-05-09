/* Top 3 product categories whose most-used payment type registers the highest
   number of payments (Snowflake dialect) */
WITH category_payment_rank AS (
    SELECT
        p."product_category_name",
        pay."payment_type",
        COUNT(*) AS "n_payments",
        ROW_NUMBER() OVER (
            PARTITION BY p."product_category_name"
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_ITEMS"        i
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_PRODUCTS_DATASET"   p
      ON i."product_id" = p."product_id"
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS"     pay
      ON i."order_id"  = pay."order_id"
    WHERE p."product_category_name" IS NOT NULL
    GROUP BY
        p."product_category_name",
        pay."payment_type"
)

SELECT
    "product_category_name",
    "payment_type",
    "n_payments"
FROM category_payment_rank
WHERE rn = 1                 -- keep the most-used payment type per category
ORDER BY "n_payments" DESC NULLS LAST
LIMIT 3;