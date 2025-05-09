WITH
-- 1. each order linked only once to each product category it contains
"order_categories" AS (
    SELECT DISTINCT
           oi.order_id,
           p.product_category_name
    FROM   olist_order_items      AS oi
    JOIN   olist_products         AS p  ON p.product_id = oi.product_id
),

-- 2. count how many payment rows every (category , payment_type) receives
"category_payment_counts" AS (
    SELECT
        oc.product_category_name,
        pay.payment_type,
        COUNT(*) AS payment_count
    FROM   order_categories        AS oc
    JOIN   olist_order_payments    AS pay ON pay.order_id = oc.order_id
    GROUP  BY oc.product_category_name,
             pay.payment_type
),

-- 3. per category, keep only its most‑used payment type
"category_top_payment" AS (
    SELECT
        cpc.product_category_name,
        cpc.payment_type,
        cpc.payment_count,
        ROW_NUMBER() OVER (PARTITION BY cpc.product_category_name
                           ORDER BY cpc.payment_count DESC,
                                    cpc.payment_type) AS rn
    FROM   category_payment_counts AS cpc
)

-- 4. pick the three categories whose top payment type has the
--    highest number of payments
SELECT
    COALESCE(t.product_category_name_english,
             ctp.product_category_name)        AS product_category,
    ctp.payment_type,
    ctp.payment_count
FROM   category_top_payment  AS ctp
LEFT   JOIN product_category_name_translation AS t
       ON t.product_category_name = ctp.product_category_name
WHERE  ctp.rn = 1                       -- only the most common payment type
ORDER  BY ctp.payment_count DESC,
          product_category
LIMIT  3;