WITH delivered_items AS (   -- every item that belongs to a *delivered* order
    SELECT 
        oi."seller_id",
        oi."order_id",
        oi."price",
        oi."freight_value"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_ITEMS"  oi
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS"       o
          ON oi."order_id" = o."order_id"
    WHERE o."order_status" = 'delivered'
),
delivered_items_customers AS (  -- add the shopper’s unique id
    SELECT 
        di.*,
        c."customer_unique_id"
    FROM delivered_items                                           di
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS"  o
          ON di."order_id" = o."order_id"
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_CUSTOMERS" c
          ON o."customer_id" = c."customer_id"
)
SELECT * 
FROM (

    /* 1. Seller that reached the largest universe of unique customers */
    SELECT 
        'Most Distinct Customer Unique IDs'          AS "achievement",
        "seller_id",
        DISTINCT_CUSTOMERS                           AS "value"
    FROM (
        SELECT 
            dic."seller_id",
            COUNT(DISTINCT dic."customer_unique_id") AS DISTINCT_CUSTOMERS,
            ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT dic."customer_unique_id") DESC NULLS LAST) AS rn
        FROM delivered_items_customers dic
        GROUP BY dic."seller_id"
    )
    WHERE rn = 1

    UNION ALL

    /* 2. Seller with the highest profit (price – freight) */
    SELECT 
        'Highest Profit (Price - Freight)'           AS "achievement",
        "seller_id",
        PROFIT                                       AS "value"
    FROM (
        SELECT
            di."seller_id",
            ROUND(SUM(di."price" - di."freight_value"),4) AS PROFIT,
            ROW_NUMBER() OVER (ORDER BY SUM(di."price" - di."freight_value") DESC NULLS LAST) AS rn
        FROM delivered_items di
        GROUP BY di."seller_id"
    )
    WHERE rn = 1

    UNION ALL

    /* 3. Seller that handled the greatest number of distinct delivered orders */
    SELECT
        'Most Distinct Orders'                       AS "achievement",
        "seller_id",
        ORDERS_CT                                    AS "value"
    FROM (
        SELECT
            di."seller_id",
            COUNT(DISTINCT di."order_id") AS ORDERS_CT,
            ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT di."order_id") DESC NULLS LAST) AS rn
        FROM delivered_items di
        GROUP BY di."seller_id"
    )
    WHERE rn = 1

    UNION ALL

    /* 4. Seller that collected the most 5-star reviews */
    SELECT
        'Most 5-Star Ratings'                        AS "achievement",
        "seller_id",
        FIVE_STAR                                    AS "value"
    FROM (
        SELECT
            sr."seller_id",
            sr.five_star_reviews                     AS FIVE_STAR,
            ROW_NUMBER() OVER (ORDER BY sr.five_star_reviews DESC NULLS LAST) AS rn
        FROM (
            SELECT 
                di."seller_id",
                COUNT(DISTINCT r."review_id") AS five_star_reviews
            FROM delivered_items di
            JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_REVIEWS" r
                  ON di."order_id" = r."order_id"
            WHERE r."review_score" = 5
            GROUP BY di."seller_id"
        ) sr
    )
    WHERE rn = 1
)
ORDER BY "achievement";