WITH category_payment_counts AS (
    SELECT p."product_category_name" AS category,
           pay."payment_type",
           COUNT(*) AS payments
    FROM   "olist_order_items"    AS oi
    JOIN   "olist_products"       AS p   ON p."product_id" = oi."product_id"
    JOIN   "olist_order_payments" AS pay ON pay."order_id" = oi."order_id"
    GROUP  BY p."product_category_name",
              pay."payment_type"
),
category_max AS (
    SELECT category,
           MAX(payments) AS max_payments
    FROM   category_payment_counts
    GROUP  BY category
)
SELECT cpc.category        AS "product_category_name",
       cpc."payment_type"  AS "most_common_payment_type",
       cpc.payments        AS "num_payments"
FROM   category_payment_counts AS cpc
JOIN   category_max            AS cm
  ON   cpc.category = cm.category
 AND   cpc.payments = cm.max_payments
ORDER  BY cpc.payments DESC
LIMIT 3;