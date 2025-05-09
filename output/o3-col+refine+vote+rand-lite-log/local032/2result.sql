WITH delivered_items AS (
    /* every item that belongs to a delivered order */
    SELECT  oi.seller_id,
            o.order_id,
            c.customer_unique_id,
            oi.price,
            oi.freight_value
    FROM    olist_order_items   AS oi
    JOIN    olist_orders        AS o  ON o.order_id    = oi.order_id
    JOIN    olist_customers     AS c  ON c.customer_id = o.customer_id
    WHERE   o.order_status = 'delivered'
),
seller_metrics AS (
    /* core seller-level figures */
    SELECT  seller_id,
            COUNT(DISTINCT customer_unique_id)                 AS distinct_customers,
            SUM(price - freight_value)                         AS profit,
            COUNT(DISTINCT order_id)                           AS distinct_orders
    FROM    delivered_items
    GROUP BY seller_id
),
five_star AS (
    /* 5-star reviews per seller on delivered orders */
    SELECT  oi.seller_id,
            COUNT(*)                                           AS five_star_reviews
    FROM    olist_order_items     AS oi
    JOIN    olist_orders          AS o  ON o.order_id = oi.order_id
    JOIN    olist_order_reviews   AS r  ON r.order_id = o.order_id
    WHERE   o.order_status = 'delivered'
      AND   r.review_score = 5
    GROUP BY oi.seller_id
),
top_distinct AS (
    SELECT 'most_distinct_customers' AS description,
           seller_id,
           distinct_customers        AS metric_value
    FROM   seller_metrics
    ORDER BY distinct_customers DESC
    LIMIT 1
),
top_profit AS (
    SELECT 'highest_profit'          AS description,
           seller_id,
           ROUND(profit,4)           AS metric_value
    FROM   seller_metrics
    ORDER BY profit DESC
    LIMIT 1
),
top_orders AS (
    SELECT 'most_distinct_orders'    AS description,
           seller_id,
           distinct_orders           AS metric_value
    FROM   seller_metrics
    ORDER BY distinct_orders DESC
    LIMIT 1
),
top_reviews AS (
    SELECT 'most_five_star_reviews'  AS description,
           seller_id,
           five_star_reviews         AS metric_value
    FROM   five_star
    ORDER BY five_star_reviews DESC
    LIMIT 1
)

SELECT * FROM top_distinct
UNION ALL
SELECT * FROM top_profit
UNION ALL
SELECT * FROM top_orders
UNION ALL
SELECT * FROM top_reviews;