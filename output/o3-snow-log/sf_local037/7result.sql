-- Top-3 product categories ranked by the number of payments
-- made with their respectively most-frequent payment type
WITH category_payment_cnt AS (   -- # payments per (category, payment_type)
    SELECT  p."product_category_name",
            pay."payment_type",
            COUNT(*) AS "payment_cnt"
    FROM    BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_ITEMS       oi
    JOIN    BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_PRODUCTS          p
              ON oi."product_id" = p."product_id"
    JOIN    BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_PAYMENTS    pay
              ON oi."order_id"  = pay."order_id"
    GROUP BY p."product_category_name",
             pay."payment_type"
),
ranked AS (                       -- keep only the most-common payment type per category
    SELECT  "product_category_name",
            "payment_type",
            "payment_cnt",
            ROW_NUMBER() OVER (PARTITION BY "product_category_name"
                               ORDER BY "payment_cnt" DESC NULLS LAST) AS "rn"
    FROM    category_payment_cnt
)
SELECT  "product_category_name",
        "payment_type"  AS "most_common_payment_type",
        "payment_cnt"   AS "payments_using_that_type"
FROM    ranked
WHERE   "rn" = 1                       -- most-frequent payment type in each category
ORDER BY "payment_cnt" DESC NULLS LAST -- highest #payments first
LIMIT 3;