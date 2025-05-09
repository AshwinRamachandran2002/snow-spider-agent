-- Winners in each requested category (delivered orders only)
SELECT 'Most distinct customers' AS achievement,
       s1.seller_id,
       s1.distinct_customers      AS value
FROM (
        SELECT oi.seller_id,
               COUNT(DISTINCT c.customer_unique_id) AS distinct_customers
        FROM   olist_order_items AS oi
        JOIN   olist_orders      AS o ON o.order_id   = oi.order_id
        JOIN   olist_customers   AS c ON c.customer_id = o.customer_id
        WHERE  o.order_status = 'delivered'
        GROUP  BY oi.seller_id
        ORDER  BY distinct_customers DESC
        LIMIT  1
) AS s1

UNION ALL
SELECT 'Highest profit',
       s2.seller_id,
       ROUND(s2.total_profit,4)  -- keep up to 4 decimals
FROM (
        SELECT oi.seller_id,
               SUM(oi.price - oi.freight_value) AS total_profit
        FROM   olist_order_items AS oi
        JOIN   olist_orders      AS o ON o.order_id = oi.order_id
        WHERE  o.order_status = 'delivered'
        GROUP  BY oi.seller_id
        ORDER  BY total_profit DESC
        LIMIT  1
) AS s2

UNION ALL
SELECT 'Most distinct orders',
       s3.seller_id,
       s3.distinct_orders        AS value
FROM (
        SELECT oi.seller_id,
               COUNT(DISTINCT oi.order_id) AS distinct_orders
        FROM   olist_order_items AS oi
        JOIN   olist_orders      AS o ON o.order_id = oi.order_id
        WHERE  o.order_status = 'delivered'
        GROUP  BY oi.seller_id
        ORDER  BY distinct_orders DESC
        LIMIT  1
) AS s3

UNION ALL
SELECT 'Most 5-star reviews',
       s4.seller_id,
       s4.five_star_reviews      AS value
FROM (
        SELECT oi.seller_id,
               COUNT(*) AS five_star_reviews
        FROM   olist_order_items  AS oi
        JOIN   olist_order_reviews AS r ON r.order_id = oi.order_id
        JOIN   olist_orders        AS o ON o.order_id = oi.order_id
        WHERE  o.order_status = 'delivered'
          AND  r.review_score = 5
        GROUP  BY oi.seller_id
        ORDER  BY five_star_reviews DESC
        LIMIT  1
) AS s4;