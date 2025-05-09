SELECT 'Most distinct customer unique IDs' AS description,
       seller_id,
       value
FROM (
    SELECT oi.seller_id,
           COUNT(DISTINCT c.customer_unique_id) AS value
    FROM olist_order_items AS oi
    JOIN olist_orders      AS o ON o.order_id = oi.order_id
    JOIN olist_customers   AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
    ORDER BY value DESC, seller_id
    LIMIT 1
)

UNION ALL

SELECT 'Highest total profit',
       seller_id,
       value
FROM (
    SELECT oi.seller_id,
           ROUND(SUM(oi.price - oi.freight_value), 4) AS value
    FROM olist_order_items AS oi
    JOIN olist_orders      AS o ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
    ORDER BY value DESC, seller_id
    LIMIT 1
)

UNION ALL

SELECT 'Most distinct orders delivered',
       seller_id,
       value
FROM (
    SELECT oi.seller_id,
           COUNT(DISTINCT oi.order_id) AS value
    FROM olist_order_items AS oi
    JOIN olist_orders      AS o ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
    ORDER BY value DESC, seller_id
    LIMIT 1
)

UNION ALL

SELECT 'Most 5-star reviews',
       seller_id,
       value
FROM (
    SELECT oi.seller_id,
           COUNT(DISTINCT r.review_id) AS value
    FROM olist_order_items   AS oi
    JOIN olist_orders        AS o ON o.order_id = oi.order_id
    JOIN olist_order_reviews AS r ON r.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND r.review_score = 5
    GROUP BY oi.seller_id
    ORDER BY value DESC, seller_id
    LIMIT 1
);