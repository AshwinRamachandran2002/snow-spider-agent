SELECT 'Most distinct customers' AS description,
       seller_id,
       value
FROM (
    SELECT oi.seller_id,
           COUNT(DISTINCT c.customer_unique_id) AS value
    FROM olist_order_items oi
    JOIN olist_orders  o  USING (order_id)
    JOIN olist_customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
    ORDER BY value DESC
    LIMIT 1
)
UNION ALL
SELECT 'Highest profit',
       seller_id,
       value
FROM (
    SELECT oi.seller_id,
           ROUND(SUM(oi.price - oi.freight_value), 4) AS value
    FROM olist_order_items oi
    JOIN olist_orders o USING (order_id)
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
    ORDER BY value DESC
    LIMIT 1
)
UNION ALL
SELECT 'Most delivered orders',
       seller_id,
       value
FROM (
    SELECT oi.seller_id,
           COUNT(DISTINCT oi.order_id) AS value
    FROM olist_order_items oi
    JOIN olist_orders o USING (order_id)
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
    ORDER BY value DESC
    LIMIT 1
)
UNION ALL
SELECT 'Most 5-star reviews',
       seller_id,
       value
FROM (
    SELECT oi.seller_id,
           COUNT(*) AS value
    FROM olist_order_reviews r
    JOIN olist_orders       o  USING (order_id)
    JOIN olist_order_items  oi USING (order_id)
    WHERE o.order_status = 'delivered'
      AND r.review_score = 5
    GROUP BY oi.seller_id
    ORDER BY value DESC
    LIMIT 1
);