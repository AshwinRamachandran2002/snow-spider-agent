WITH order_categories AS (
    SELECT DISTINCT
           oi.order_id,
           p.product_category_name
    FROM olist_order_items AS oi
    JOIN olist_products  AS p
      ON p.product_id = oi.product_id
),        
category_payment_counts AS (
    SELECT
           oc.product_category_name,
           op.payment_type,
           COUNT(*) AS payment_count
    FROM order_categories AS oc
    JOIN olist_order_payments AS op
      ON op.order_id = oc.order_id
    GROUP BY
           oc.product_category_name,
           op.payment_type
),
category_top_payment AS (
    SELECT
           product_category_name,
           payment_type,
           payment_count,
           ROW_NUMBER() OVER (
               PARTITION BY product_category_name
               ORDER BY payment_count DESC, payment_type ASC
           ) AS rn
    FROM category_payment_counts
)
SELECT
       COALESCE(t.product_category_name_english,
                c.product_category_name) AS product_category,
       c.payment_type,
       c.payment_count
FROM category_top_payment AS c
LEFT JOIN product_category_name_translation AS t
       ON t.product_category_name = c.product_category_name
WHERE c.rn = 1
ORDER BY c.payment_count DESC,
         product_category
LIMIT 3;