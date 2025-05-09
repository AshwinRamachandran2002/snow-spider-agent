/* ----------------------------------------------------------
   TOP-PERFORMING SELLERS (ONLY “delivered” ORDERS CONSIDERED)
   ----------------------------------------------------------*/
WITH delivered_orders AS (   -- only delivered orders
    SELECT "order_id",
           "customer_id"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
    WHERE "order_status" = 'delivered'
),

/* map orders -> customer_unique_id */
customer_map AS (
    SELECT o."order_id",
           c."customer_unique_id"
    FROM delivered_orders             o
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_CUSTOMERS c
      ON o."customer_id" = c."customer_id"
),

/* order items belonging to delivered orders */
order_items_delivered AS (
    SELECT oi."seller_id",
           oi."order_id",
           oi."price",
           oi."freight_value"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_ITEMS oi
    JOIN delivered_orders o
      ON oi."order_id" = o."order_id"
),

/* 1. distinct customer IDs per seller */
seller_customer_cnt AS (
    SELECT oi."seller_id",
           COUNT(DISTINCT cm."customer_unique_id") AS cnt_customers
    FROM order_items_delivered oi
    JOIN customer_map          cm ON oi."order_id" = cm."order_id"
    GROUP BY oi."seller_id"
),
top_customer_seller AS (
    SELECT 'Highest distinct customers' AS achievement,
           "seller_id",
           cnt_customers        AS value,
           ROW_NUMBER() OVER (ORDER BY cnt_customers DESC NULLS LAST, "seller_id") AS rn
    FROM seller_customer_cnt
),

/* 2. total profit (price – freight) per seller */
seller_profit AS (
    SELECT "seller_id",
           SUM("price" - "freight_value") AS profit
    FROM order_items_delivered
    GROUP BY "seller_id"
),
top_profit_seller AS (
    SELECT 'Highest profit' AS achievement,
           "seller_id",
           profit            AS value,
           ROW_NUMBER() OVER (ORDER BY profit DESC NULLS LAST, "seller_id") AS rn
    FROM seller_profit
),

/* 3. distinct orders per seller */
seller_orders_cnt AS (
    SELECT "seller_id",
           COUNT(DISTINCT "order_id") AS cnt_orders
    FROM order_items_delivered
    GROUP BY "seller_id"
),
top_orders_seller AS (
    SELECT 'Highest distinct orders' AS achievement,
           "seller_id",
           cnt_orders       AS value,
           ROW_NUMBER() OVER (ORDER BY cnt_orders DESC NULLS LAST, "seller_id") AS rn
    FROM seller_orders_cnt
),

/* 4. 5-star reviews per seller */
five_star AS (
    SELECT oi."seller_id",
           COUNT(*) AS five_star_cnt
    FROM order_items_delivered                           oi
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_REVIEWS r
      ON oi."order_id" = r."order_id"
    WHERE r."review_score" = 5
    GROUP BY oi."seller_id"
),
top_five_star AS (
    SELECT 'Most 5-star ratings' AS achievement,
           "seller_id",
           five_star_cnt         AS value,
           ROW_NUMBER() OVER (ORDER BY five_star_cnt DESC NULLS LAST, "seller_id") AS rn
    FROM five_star
)

/* ----------------------------------------------------------
   UNION THE FOUR WINNERS
   ----------------------------------------------------------*/
SELECT  achievement        AS "description",
        "seller_id"        AS "seller_id",
        value              AS "value"
FROM   (SELECT * FROM top_customer_seller WHERE rn = 1
        UNION ALL
        SELECT * FROM top_profit_seller   WHERE rn = 1
        UNION ALL
        SELECT * FROM top_orders_seller   WHERE rn = 1
        UNION ALL
        SELECT * FROM top_five_star       WHERE rn = 1)
ORDER BY "description";