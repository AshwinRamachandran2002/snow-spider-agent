WITH order_category AS (
    SELECT op.order_id,
           op.payment_type,
           p.product_category_name
    FROM olist_order_payments AS op
    JOIN olist_order_items  AS oi ON op.order_id = oi.order_id
    JOIN olist_products     AS p  ON oi.product_id = p.product_id
),
category_payment_counts AS (
    SELECT product_category_name      AS category,
           payment_type,
           COUNT(*)                   AS payments_cnt
    FROM order_category
    GROUP BY product_category_name, payment_type
),
max_per_category AS (
    SELECT category,
           MAX(payments_cnt) AS max_cnt
    FROM category_payment_counts
    GROUP BY category
),
preferred_payment AS (               -- choose one payment type per category
    SELECT cpc.category,
           MIN(cpc.payment_type) AS payment_type,   -- tie‑breaker
           mpc.max_cnt          AS payments_cnt
    FROM category_payment_counts AS cpc
    JOIN max_per_category       AS mpc
      ON cpc.category = mpc.category
     AND cpc.payments_cnt = mpc.max_cnt
    GROUP BY cpc.category
)
SELECT category             AS product_category_name,
       payment_type, 
       payments_cnt         AS number_of_payments
FROM preferred_payment
ORDER BY payments_cnt DESC,
         category ASC
LIMIT 3;