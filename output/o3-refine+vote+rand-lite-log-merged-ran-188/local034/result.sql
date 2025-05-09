WITH item_category AS (
    /* every (order_id, category) pair just once */
    SELECT DISTINCT oi.order_id,
           p.product_category_name AS category
    FROM olist_order_items  AS oi
    JOIN olist_products     AS p  ON p.product_id = oi.product_id
),
payment_by_category AS (
    /* how many payment records each payment type has inside each category */
    SELECT ic.category,
           op.payment_type,
           COUNT(*) AS payment_cnt
    FROM item_category        AS ic
    JOIN olist_order_payments AS op ON op.order_id = ic.order_id
    GROUP BY ic.category, op.payment_type
),
preferred_method AS (
    /* keep only the count of the most used payment method in every category */
    SELECT category,
           MAX(payment_cnt) AS max_payment_cnt
    FROM payment_by_category
    GROUP BY category
)
SELECT ROUND(AVG(max_payment_cnt), 4) AS avg_payments_most_preferred_method
FROM preferred_method;