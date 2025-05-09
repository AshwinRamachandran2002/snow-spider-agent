WITH "ITEM_CATEGORIES" AS (
    SELECT DISTINCT
           oi."order_id",
           pd."product_category_name"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_ITEMS"  oi
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_PRODUCTS_DATASET" pd
      ON oi."product_id" = pd."product_id"
    WHERE pd."product_category_name" IS NOT NULL
),
"PAYMENTS_WITH_CATEGORY" AS (
    SELECT
           ic."product_category_name",
           op."payment_type"
    FROM "ITEM_CATEGORIES"                        ic
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS" op
      ON ic."order_id" = op."order_id"
),
"PAYMENT_COUNTS" AS (
    SELECT
           "product_category_name",
           "payment_type",
           COUNT(*) AS "payment_count"
    FROM "PAYMENTS_WITH_CATEGORY"
    GROUP BY "product_category_name", "payment_type"
),
"PREFERRED_PAYMENT" AS (
    SELECT
           "product_category_name",
           "payment_count",
           ROW_NUMBER() OVER (PARTITION BY "product_category_name"
                              ORDER BY "payment_count" DESC, "payment_type") AS rn
    FROM "PAYMENT_COUNTS"
)
SELECT AVG("payment_count") AS "avg_payment_count_most_preferred"
FROM   "PREFERRED_PAYMENT"
WHERE  rn = 1;