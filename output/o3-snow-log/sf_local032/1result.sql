WITH delivered_orders AS (           -- only delivered orders
    SELECT "order_id",
           "customer_id"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
    WHERE "order_status" = 'delivered'
),
delivered_items AS (                 -- items that belong to delivered orders
    SELECT  i."seller_id",
            o."order_id",
            o."customer_id",
            i."price",
            i."freight_value"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_ITEMS  i
    JOIN delivered_orders                                            o
      ON i."order_id" = o."order_id"
),
seller_customers AS (                -- link sellers to customer_unique_id
    SELECT di."seller_id",
           c."customer_unique_id"
    FROM delivered_items                                                 di
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_CUSTOMERS       c
      ON di."customer_id" = c."customer_id"
),
seller_reviews AS (                  -- 5-star reviews linked to sellers
    SELECT di."seller_id",
           r."review_id"
    FROM delivered_items                                                 di
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_REVIEWS   r
      ON di."order_id" = r."order_id"
    WHERE r."review_score" = 5
),
-- seller with most distinct customer_unique_id
customer_rank AS (
    SELECT "seller_id",
           COUNT(DISTINCT "customer_unique_id") AS metric_value
    FROM seller_customers
    GROUP BY "seller_id"
    QUALIFY metric_value = MAX(metric_value) OVER ()
),
-- seller with highest profit (price − freight)
profit_rank AS (
    SELECT "seller_id",
           ROUND(SUM("price" - "freight_value"),4) AS metric_value
    FROM delivered_items
    GROUP BY "seller_id"
    QUALIFY metric_value = MAX(metric_value) OVER ()
),
-- seller with most distinct orders
orders_rank AS (
    SELECT "seller_id",
           COUNT(DISTINCT "order_id") AS metric_value
    FROM delivered_items
    GROUP BY "seller_id"
    QUALIFY metric_value = MAX(metric_value) OVER ()
),
-- seller with most 5-star reviews
reviews_rank AS (
    SELECT "seller_id",
           COUNT(*) AS metric_value
    FROM seller_reviews
    GROUP BY "seller_id"
    QUALIFY metric_value = MAX(metric_value) OVER ()
)
-- final union of the four achievements
SELECT 'Most distinct customers' AS achievement,
       "seller_id",
       metric_value
FROM customer_rank
UNION ALL
SELECT 'Highest profit',
       "seller_id",
       metric_value
FROM profit_rank
UNION ALL
SELECT 'Most distinct orders',
       "seller_id",
       metric_value
FROM orders_rank
UNION ALL
SELECT 'Most 5-star reviews',
       "seller_id",
       metric_value
FROM reviews_rank;