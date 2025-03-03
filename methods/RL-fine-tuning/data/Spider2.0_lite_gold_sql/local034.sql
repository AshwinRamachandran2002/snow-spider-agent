WITH counts_table AS (
    SELECT op.product_category_name, opp.payment_type, COUNT(*) AS payment_count
    FROM olist_order_items oi
    JOIN olist_products op ON oi.product_id = op.product_id
    JOIN olist_order_payments opp ON oi.order_id = opp.order_id
    GROUP BY op.product_category_name, opp.payment_type
),
most_preferred_payment AS (
    SELECT c.product_category_name, c.payment_type
    FROM counts_table c
    JOIN (
        SELECT product_category_name, MAX(payment_count) AS max_count
        FROM counts_table
        GROUP BY product_category_name
    ) AS m
    ON c.product_category_name = m.product_category_name
       AND c.payment_count = m.max_count
)
SELECT t.product_category_name, ROUND(AVG(t.total_payments), 4) AS avg_total_payment_count
FROM (
    SELECT op.product_category_name, opp.payment_type, oi.order_id, COUNT(*) AS total_payments
    FROM olist_order_items oi
    JOIN olist_products op ON oi.product_id = op.product_id
    JOIN olist_order_payments opp ON oi.order_id = opp.order_id
    GROUP BY op.product_category_name, opp.payment_type, oi.order_id
) AS t
JOIN most_preferred_payment mp
ON t.product_category_name = mp.product_category_name
   AND t.payment_type = mp.payment_type
GROUP BY t.product_category_name
ORDER BY t.product_category_name;