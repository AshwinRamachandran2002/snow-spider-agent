WITH order_category AS (         -- each order with at least one product category
    SELECT DISTINCT 
           ooi.order_id,
           op.product_category_name AS category
    FROM olist_order_items ooi
    JOIN olist_products op
         ON ooi.product_id = op.product_id
),    
category_payment_counts AS (     -- payments count by category & payment type
    SELECT 
           oc.category,
           oop.payment_type,
           COUNT(DISTINCT oc.order_id) AS payments_cnt
    FROM order_category oc
    JOIN olist_order_payments oop
         ON oc.order_id = oop.order_id
    GROUP BY oc.category, oop.payment_type
),
category_mode AS (               -- most‑used payment type within each category
    SELECT 
           category,
           payment_type,
           payments_cnt,
           RANK() OVER (PARTITION BY category
                        ORDER BY payments_cnt DESC, payment_type) AS rnk
    FROM category_payment_counts
),
category_top AS (                -- retain only the mode payment type per category
    SELECT category,
           payment_type,
           payments_cnt
    FROM category_mode
    WHERE rnk = 1
)
SELECT 
       category           AS product_category_name,
       payment_type       AS most_common_payment_type,
       payments_cnt       AS number_of_payments
FROM category_top
ORDER BY payments_cnt DESC, category
LIMIT 3;