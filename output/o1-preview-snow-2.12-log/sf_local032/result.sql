WITH delivered_orders AS (
    SELECT "order_id", "customer_id"
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDERS"
    WHERE "order_status" = 'delivered'
),
seller_customers AS (
    SELECT oi."seller_id", COUNT(DISTINCT c."customer_unique_id") AS "distinct_customers"
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_ITEMS" oi
    JOIN delivered_orders o
        ON oi."order_id" = o."order_id"
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_CUSTOMERS" c
        ON o."customer_id" = c."customer_id"
    GROUP BY oi."seller_id"
),
seller_profits AS (
    SELECT oi."seller_id", SUM(oi."price") AS "total_profit"
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_ITEMS" oi
    JOIN delivered_orders o
        ON oi."order_id" = o."order_id"
    GROUP BY oi."seller_id"
),
seller_orders AS (
    SELECT oi."seller_id", COUNT(DISTINCT oi."order_id") AS "distinct_orders"
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_ITEMS" oi
    JOIN delivered_orders o
        ON oi."order_id" = o."order_id"
    GROUP BY oi."seller_id"
),
five_star_orders AS (
    SELECT DISTINCT "order_id"
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_REVIEWS"
    WHERE "review_score" = 5
),
seller_reviews AS (
    SELECT oi."seller_id", COUNT(DISTINCT oi."order_id") AS "five_star_reviews"
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_ITEMS" oi
    JOIN five_star_orders fso
        ON oi."order_id" = fso."order_id"
    JOIN delivered_orders o
        ON oi."order_id" = o."order_id"
    GROUP BY oi."seller_id"
),
max_customers AS (
    SELECT sc."seller_id", sc."distinct_customers"
    FROM seller_customers sc
    WHERE sc."distinct_customers" = (SELECT MAX("distinct_customers") FROM seller_customers)
),
max_profit AS (
    SELECT sp."seller_id", sp."total_profit"
    FROM seller_profits sp
    WHERE sp."total_profit" = (SELECT MAX("total_profit") FROM seller_profits)
),
max_orders AS (
    SELECT so."seller_id", so."distinct_orders"
    FROM seller_orders so
    WHERE so."distinct_orders" = (SELECT MAX("distinct_orders") FROM seller_orders)
),
max_reviews AS (
    SELECT sr."seller_id", sr."five_star_reviews"
    FROM seller_reviews sr
    WHERE sr."five_star_reviews" = (SELECT MAX("five_star_reviews") FROM seller_reviews)
)
SELECT 'Highest_number_of_distinct_customers' AS "Metric",
       mc."seller_id" AS "Seller_ID", CAST(mc."distinct_customers" AS VARCHAR) AS "Value"
FROM max_customers mc

UNION ALL

SELECT 'Highest_profit' AS "Metric",
       mp."seller_id" AS "Seller_ID", TO_VARCHAR(ROUND(mp."total_profit", 4)) AS "Value"
FROM max_profit mp

UNION ALL

SELECT 'Highest_number_of_distinct_orders' AS "Metric",
       mo."seller_id" AS "Seller_ID", CAST(mo."distinct_orders" AS VARCHAR) AS "Value"
FROM max_orders mo

UNION ALL

SELECT 'Most_5-star_ratings' AS "Metric",
       mr."seller_id" AS "Seller_ID", CAST(mr."five_star_reviews" AS VARCHAR) AS "Value"
FROM max_reviews mr;