WITH order_categories AS (
    /* link every order to the product categories it contains */
    SELECT DISTINCT oi.order_id,
           p.product_category_name
    FROM olist_order_items AS oi
    JOIN olist_products      AS p  ON p.product_id = oi.product_id
),
payments_per_category AS (
    /* count each payment (row) by category & payment type */
    SELECT oc.product_category_name      AS category,
           op.payment_type,
           COUNT(*)                      AS payments_cnt
    FROM order_categories   AS oc
    JOIN olist_order_payments AS op ON op.order_id = oc.order_id
    GROUP BY oc.product_category_name,
             op.payment_type
),
preferred_method AS (
    /* keep only the payment method with the highest count in each category */
    SELECT category,
           payment_type,
           payments_cnt,
           ROW_NUMBER() OVER (PARTITION BY category
                              ORDER BY payments_cnt DESC, payment_type) AS rn
    FROM payments_per_category
)
SELECT ROUND(AVG(payments_cnt),4) AS average_preferred_payment_count
FROM preferred_method
WHERE rn = 1;