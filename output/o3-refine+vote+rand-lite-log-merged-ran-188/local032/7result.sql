WITH delivered AS (
    SELECT *
    FROM olist_orders
    WHERE order_status = 'delivered'
),
base AS (
    SELECT  oi.seller_id,
            o.order_id,
            (oi.price - oi.freight_value)            AS profit,
            c.customer_unique_id
    FROM    olist_order_items AS oi
    JOIN    delivered          AS o  USING (order_id)
    JOIN    olist_customers    AS c  ON c.customer_id = o.customer_id
),
customer_cnt AS (
    SELECT seller_id,
           COUNT(DISTINCT customer_unique_id) AS val
    FROM   base
    GROUP BY seller_id
),
profit_sum AS (
    SELECT seller_id,
           SUM(profit) AS val
    FROM   base
    GROUP BY seller_id
),
order_cnt AS (
    SELECT seller_id,
           COUNT(DISTINCT order_id) AS val
    FROM   base
    GROUP BY seller_id
),
five_star AS (
    SELECT  oi.seller_id,
            COUNT(*) AS val
    FROM    olist_order_items   AS oi
    JOIN    delivered           AS o  USING (order_id)
    JOIN    olist_order_reviews AS r  ON r.order_id = oi.order_id
    WHERE   r.review_score = 5
    GROUP BY oi.seller_id
)

SELECT 'Most distinct customer_unique_ids' AS achievement,
       seller_id,
       val AS value
FROM   customer_cnt
WHERE  val = (SELECT MAX(val) FROM customer_cnt)

UNION ALL
SELECT 'Highest total profit (price - freight)',
       seller_id,
       val
FROM   profit_sum
WHERE  val = (SELECT MAX(val) FROM profit_sum)

UNION ALL
SELECT 'Most distinct delivered orders',
       seller_id,
       val
FROM   order_cnt
WHERE  val = (SELECT MAX(val) FROM order_cnt)

UNION ALL
SELECT 'Most 5-star reviews',
       seller_id,
       val
FROM   five_star
WHERE  val = (SELECT MAX(val) FROM five_star);