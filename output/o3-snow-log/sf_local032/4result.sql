WITH
/* ------------------------------------------------------------------ */
/* 1. keep only delivered orders                                      */
delivered_orders AS (         
    SELECT 
        o."order_id",
        o."customer_id"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS" o
    WHERE o."order_status" = 'delivered'
),

/* ------------------------------------------------------------------ */
/* 2. order items (needed for seller, price, freight)                 */
order_items AS (               
    SELECT
        oi."order_id",
        oi."seller_id",
        oi."price",
        oi."freight_value"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_ITEMS" oi
),

/* ------------------------------------------------------------------ */
/* 3. customers to reach customer_unique_id                           */
customers AS (                 
    SELECT
        c."customer_id",
        c."customer_unique_id"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_CUSTOMERS" c
),

/* ------------------------------------------------------------------ */
/* 4. only 5-star reviews                                             */
reviews_5stars AS (            
    SELECT
        r."order_id",
        r."review_id"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_REVIEWS" r
    WHERE r."review_score" = 5
),

/* ------------------------------------------------------------------ */
/* 5. seller with MOST DISTINCT CUSTOMER UNIQUE IDs                   */
seller_distinct_customers AS ( 
    SELECT
        oi."seller_id",
        COUNT(DISTINCT cu."customer_unique_id")       AS value_customers
    FROM delivered_orders d
    JOIN order_items        oi ON oi."order_id" = d."order_id"
    JOIN customers          cu ON cu."customer_id"   = d."customer_id"
    GROUP BY oi."seller_id"
    QUALIFY ROW_NUMBER() OVER (ORDER BY value_customers DESC) = 1
),

/* ------------------------------------------------------------------ */
/* 6. seller with HIGHEST PROFIT (Σ(price – freight_value))           */
seller_highest_profit AS (     
    SELECT
        oi."seller_id",
        SUM(oi."price" - oi."freight_value")          AS value_profit
    FROM delivered_orders d
    JOIN order_items oi ON oi."order_id" = d."order_id"
    GROUP BY oi."seller_id"
    QUALIFY ROW_NUMBER() OVER (ORDER BY value_profit DESC) = 1
),

/* ------------------------------------------------------------------ */
/* 7. seller with MOST DISTINCT ORDERS                                */
seller_distinct_orders AS (    
    SELECT
        oi."seller_id",
        COUNT(DISTINCT oi."order_id")                 AS value_orders
    FROM delivered_orders d
    JOIN order_items oi ON oi."order_id" = d."order_id"
    GROUP BY oi."seller_id"
    QUALIFY ROW_NUMBER() OVER (ORDER BY value_orders DESC) = 1
),

/* ------------------------------------------------------------------ */
/* 8. seller with MOST 5-STAR REVIEWS                                 */
seller_5star_reviews AS (      
    SELECT
        oi."seller_id",
        COUNT(DISTINCT rv."review_id")                AS value_5stars
    FROM reviews_5stars  rv
    JOIN delivered_orders d ON d."order_id" = rv."order_id"
    JOIN order_items     oi ON oi."order_id" = rv."order_id"
    GROUP BY oi."seller_id"
    QUALIFY ROW_NUMBER() OVER (ORDER BY value_5stars DESC) = 1
)

/* ------------------------------------------------------------------ */
/* 9. put everything together                                         */
SELECT
    'Most Distinct Customer Unique IDs'  AS "achievement",
    sdc."seller_id"                      AS "seller_id",
    sdc.value_customers                  AS "value"
FROM seller_distinct_customers sdc

UNION ALL
SELECT
    'Highest Profit'                     AS "achievement",
    shp."seller_id"                      AS "seller_id",
    shp.value_profit                     AS "value"
FROM seller_highest_profit shp

UNION ALL
SELECT
    'Most Distinct Orders'               AS "achievement",
    sdo."seller_id"                      AS "seller_id",
    sdo.value_orders                     AS "value"
FROM seller_distinct_orders sdo

UNION ALL
SELECT
    'Most 5-Star Reviews'                AS "achievement",
    s5r."seller_id"                      AS "seller_id",
    s5r.value_5stars                     AS "value"
FROM seller_5star_reviews s5r;