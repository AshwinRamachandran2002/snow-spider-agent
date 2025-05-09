SELECT 'Highest_number_of_distinct_customers' AS "Metric", t1."seller_id" AS "Seller_ID", t1."cnt" AS "Value"
FROM (
    SELECT oi."seller_id", COUNT(DISTINCT c."customer_unique_id") AS "cnt"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_ITEMS oi
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS o ON oi."order_id" = o."order_id"
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_CUSTOMERS c ON o."customer_id" = c."customer_id"
    WHERE o."order_status" = 'delivered'
    GROUP BY oi."seller_id"
    ORDER BY "cnt" DESC NULLS LAST, oi."seller_id" ASC
    LIMIT 1
) t1

UNION ALL

SELECT 'Highest_profit' AS "Metric", t2."seller_id" AS "Seller_ID", ROUND(t2."total_sales", 4) AS "Value"
FROM (
    SELECT oi."seller_id", SUM(oi."price") AS "total_sales"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_ITEMS oi
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS o ON oi."order_id" = o."order_id"
    WHERE o."order_status" = 'delivered'
    GROUP BY oi."seller_id"
    ORDER BY "total_sales" DESC NULLS LAST, oi."seller_id" ASC
    LIMIT 1
) t2

UNION ALL

SELECT 'Highest_number_of_distinct_orders' AS "Metric", t3."seller_id" AS "Seller_ID", t3."order_count" AS "Value"
FROM (
    SELECT oi."seller_id", COUNT(DISTINCT oi."order_id") AS "order_count"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_ITEMS oi
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS o ON oi."order_id" = o."order_id"
    WHERE o."order_status" = 'delivered'
    GROUP BY oi."seller_id"
    ORDER BY "order_count" DESC NULLS LAST, oi."seller_id" ASC
    LIMIT 1
) t3

UNION ALL

SELECT 'Most_5-star_ratings' AS "Metric", t4."seller_id" AS "Seller_ID", t4."five_star_count" AS "Value"
FROM (
    SELECT oi."seller_id", COUNT(*) AS "five_star_count"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_ITEMS oi
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS o ON oi."order_id" = o."order_id"
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_REVIEWS r ON oi."order_id" = r."order_id"
    WHERE o."order_status" = 'delivered' AND r."review_score" = 5
    GROUP BY oi."seller_id"
    ORDER BY "five_star_count" DESC NULLS LAST, oi."seller_id" ASC
    LIMIT 1
) t4;