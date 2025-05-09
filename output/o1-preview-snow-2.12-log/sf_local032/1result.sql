SELECT 'Highest_number_of_distinct_customers' AS "Metric", t1."seller_id" AS "Seller_ID", t1."distinct_customers" AS "Value"
FROM (
    SELECT t."seller_id", COUNT(DISTINCT o."customer_id") AS "distinct_customers"
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_ITEMS" t
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDERS" o
        ON t."order_id" = o."order_id"
    WHERE o."order_status" = 'delivered'
    GROUP BY t."seller_id"
    ORDER BY "distinct_customers" DESC NULLS LAST
    LIMIT 1
) t1

UNION ALL

SELECT 'Highest_profit' AS "Metric", t2."seller_id" AS "Seller_ID", ROUND(t2."total_profit", 4) AS "Value"
FROM (
    SELECT t."seller_id", SUM(t."price") AS "total_profit"
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_ITEMS" t
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDERS" o
        ON t."order_id" = o."order_id"
    WHERE o."order_status" = 'delivered'
    GROUP BY t."seller_id"
    ORDER BY "total_profit" DESC NULLS LAST
    LIMIT 1
) t2

UNION ALL

SELECT 'Highest_number_of_distinct_orders' AS "Metric", t3."seller_id" AS "Seller_ID", t3."number_of_orders" AS "Value"
FROM (
    SELECT t."seller_id", COUNT(DISTINCT t."order_id") AS "number_of_orders"
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_ITEMS" t
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDERS" o
        ON t."order_id" = o."order_id"
    WHERE o."order_status" = 'delivered'
    GROUP BY t."seller_id"
    ORDER BY "number_of_orders" DESC NULLS LAST
    LIMIT 1
) t3

UNION ALL

SELECT 'Most_5-star_ratings' AS "Metric", t4."seller_id" AS "Seller_ID", t4."five_star_reviews" AS "Value"
FROM (
    SELECT t."seller_id", COUNT(*) AS "five_star_reviews"
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_ITEMS" t
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_REVIEWS" r
        ON t."order_id" = r."order_id"
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDERS" o
        ON t."order_id" = o."order_id"
    WHERE o."order_status" = 'delivered' AND r."review_score" = 5
    GROUP BY t."seller_id"
    ORDER BY "five_star_reviews" DESC NULLS LAST
    LIMIT 1
) t4;