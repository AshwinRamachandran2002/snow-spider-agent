WITH cat_pay AS (
    /* count how many payment rows exist for every (category, payment_type) pair */
    SELECT p."product_category_name"                       AS category,
           pay."payment_type",
           COUNT(*)                                        AS n_payments
    FROM   "olist_order_items"      AS oi
    JOIN   "olist_products"         AS p   ON p."product_id"  = oi."product_id"
    JOIN   "olist_order_payments"   AS pay ON pay."order_id"  = oi."order_id"
    GROUP  BY category, pay."payment_type"
),
top_pay AS (
    /* keep only the payment_type with the highest number of payments per category */
    SELECT cp.category,
           cp.n_payments
    FROM   cat_pay cp
    JOIN (
        SELECT   category,
                 MAX(n_payments) AS max_pay
        FROM     cat_pay
        GROUP BY category
    ) mx
      ON mx.category = cp.category
     AND mx.max_pay  = cp.n_payments
)
SELECT ROUND(AVG(n_payments), 4) AS avg_payments_for_preferred_method
FROM   top_pay;