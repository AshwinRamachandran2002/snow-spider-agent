WITH order_categories AS (
    SELECT DISTINCT oi.order_id,
                    pr.product_category_name
    FROM olist_order_items AS oi
    JOIN olist_products    AS pr ON pr.product_id = oi.product_id
),
payments_per_category AS (
    SELECT oc.product_category_name,
           pay.payment_type,
           COUNT(*) AS num_payments
    FROM order_categories AS oc
    JOIN olist_order_payments AS pay
      ON pay.order_id = oc.order_id
    GROUP BY oc.product_category_name,
             pay.payment_type
),
preferred_method AS (
    SELECT product_category_name,
           num_payments,
           ROW_NUMBER() OVER (PARTITION BY product_category_name
                              ORDER BY num_payments DESC, payment_type) AS rn
    FROM payments_per_category
)
SELECT AVG(num_payments) AS avg_num_payments_of_preferred_method
FROM preferred_method
WHERE rn = 1;