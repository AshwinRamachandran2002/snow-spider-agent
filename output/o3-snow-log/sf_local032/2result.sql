WITH delivered_orders AS (
    SELECT 
        o."order_id",
        o."customer_id"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS" o
    WHERE o."order_status" = 'delivered'
),
order_items AS (
    SELECT 
        oi."order_id",
        oi."seller_id",
        oi."price",
        oi."freight_value"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_ITEMS" oi
),
customers AS (
    SELECT 
        c."customer_id",
        c."customer_unique_id"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_CUSTOMERS" c
),
five_star_orders AS (
    SELECT DISTINCT 
        r."order_id"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_REVIEWS" r
    WHERE r."review_score" = 5
),
base AS (
    /*  Delivered order-items joined with customer and review information   */
    SELECT
        oi."seller_id",
        do."order_id",
        c."customer_unique_id",
        oi."price",
        oi."freight_value",
        CASE WHEN fso."order_id" IS NOT NULL THEN 1 ELSE 0 END AS "is_5_star"
    FROM delivered_orders           do
    JOIN order_items                oi  ON do."order_id"    = oi."order_id"
    LEFT JOIN customers             c   ON do."customer_id" = c."customer_id"
    LEFT JOIN five_star_orders      fso ON do."order_id"    = fso."order_id"
),
aggregated AS (
    /*  One row per seller with all required metrics                      */
    SELECT
        "seller_id",
        COUNT(DISTINCT "customer_unique_id")                           AS "distinct_customers",
        SUM("price" - "freight_value")                                 AS "profit",
        COUNT(DISTINCT "order_id")                                     AS "distinct_orders",
        SUM("is_5_star")                                               AS "five_star_reviews"
    FROM base
    GROUP BY "seller_id"
),
-- Fetch the winner for each metric
winners AS (    
    SELECT 
        'seller_with_highest_distinct_customers'                       AS "description",
        (SELECT "seller_id"        FROM aggregated ORDER BY "distinct_customers" DESC NULLS LAST, "seller_id" LIMIT 1)  AS "seller_id",
        (SELECT "distinct_customers" FROM aggregated ORDER BY "distinct_customers" DESC NULLS LAST LIMIT 1)             AS "value"
    
    UNION ALL
    
    SELECT 
        'seller_with_highest_profit',
        (SELECT "seller_id"        FROM aggregated ORDER BY "profit" DESC NULLS LAST, "seller_id" LIMIT 1),
        (SELECT ROUND("profit",4)  FROM aggregated ORDER BY "profit" DESC NULLS LAST LIMIT 1)
    
    UNION ALL
    
    SELECT 
        'seller_with_highest_distinct_orders',
        (SELECT "seller_id"        FROM aggregated ORDER BY "distinct_orders" DESC NULLS LAST, "seller_id" LIMIT 1),
        (SELECT "distinct_orders"  FROM aggregated ORDER BY "distinct_orders" DESC NULLS LAST LIMIT 1)
    
    UNION ALL
    
    SELECT 
        'seller_with_most_5_star_reviews',
        (SELECT "seller_id"        FROM aggregated ORDER BY "five_star_reviews" DESC NULLS LAST, "seller_id" LIMIT 1),
        (SELECT "five_star_reviews"FROM aggregated ORDER BY "five_star_reviews" DESC NULLS LAST LIMIT 1)
)
SELECT *
FROM winners;