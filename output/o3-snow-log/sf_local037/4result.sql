/*  Top-3 product categories whose MOST-USED payment type
    (within that category) registers the largest number of payments  */

WITH cat_orders AS (   /* link every order to each product category it contains */
    SELECT DISTINCT 
           i."order_id",
           p."product_category_name"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_ITEMS"  i
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_PRODUCTS"     p
      ON i."product_id" = p."product_id"
),

cat_payments AS (      /* count payments per (category, payment type) pair */
    SELECT 
           co."product_category_name",
           pay."payment_type",
           COUNT(*) AS "num_payments"
    FROM cat_orders                                                 co
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS" pay
      ON co."order_id" = pay."order_id"
    GROUP BY 
           co."product_category_name",
           pay."payment_type"
),

ranked AS (            /* keep only the single most-common payment type in each category */
    SELECT 
           cp.*,
           ROW_NUMBER() OVER (PARTITION BY cp."product_category_name"
                              ORDER BY cp."num_payments" DESC) AS rn
    FROM cat_payments cp
)

SELECT 
       r."product_category_name",
       COALESCE(tr."product_category_name_english",'') AS "category_english",
       r."payment_type",
       r."num_payments"
FROM ranked                                  r
LEFT JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."PRODUCT_CATEGORY_NAME_TRANSLATION" tr
       ON r."product_category_name" = tr."product_category_name"
WHERE r.rn = 1                               -- most-used payment type per category
ORDER BY r."num_payments" DESC NULLS LAST
LIMIT 3;                                     -- top 3 categories overall