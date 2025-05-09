WITH "ORDER_CATEGORIES" AS (   -- each order linked once to every product category it contains
    SELECT DISTINCT
           OI."order_id",
           PR."product_category_name"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_ITEMS"  OI
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_PRODUCTS"      PR
      ON OI."product_id" = PR."product_id"
    WHERE PR."product_category_name" IS NOT NULL
),
"JOINED_PAYMENTS" AS (          -- bring in the payment information
    SELECT
           OC."product_category_name",
           PAY."payment_type"
    FROM "ORDER_CATEGORIES"                                        OC
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS" PAY
      ON OC."order_id" = PAY."order_id"
),
"PAYMENT_COUNTS" AS (           -- number of payments per category & payment type
    SELECT
           "product_category_name",
           "payment_type",
           COUNT(*) AS "payment_cnt"
    FROM "JOINED_PAYMENTS"
    GROUP BY "product_category_name", "payment_type"
),
"PREFERRED_METHOD" AS (         -- keep only the most-used method in each category
    SELECT
           "product_category_name",
           "payment_cnt",
           ROW_NUMBER() OVER (PARTITION BY "product_category_name"
                              ORDER BY "payment_cnt" DESC) AS "rn"
    FROM "PAYMENT_COUNTS"
)
SELECT
       ROUND(AVG("payment_cnt"), 4) AS "avg_total_payments_using_preferred_method"
FROM "PREFERRED_METHOD"
WHERE "rn" = 1;