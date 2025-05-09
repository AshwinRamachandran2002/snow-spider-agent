WITH delivered_orders AS (   -- all delivered orders
    SELECT 
        "order_id",
        "customer_id"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
    WHERE "order_status" = 'delivered'
),

payments_per_order AS (      -- total payment per order
    SELECT
        "order_id",
        SUM("payment_value") AS "order_payment"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_PAYMENTS
    GROUP BY "order_id"
),

city_aggregates AS (         -- aggregate to city level
    SELECT
        c."customer_city"                              AS "city",
        SUM( COALESCE(p."order_payment",0) )           AS "total_payment",
        COUNT(*)                                       AS "delivered_order_count"
    FROM delivered_orders      o
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_CUSTOMERS  c
         ON o."customer_id" = c."customer_id"
    LEFT JOIN payments_per_order p
         ON o."order_id" = p."order_id"
    GROUP BY c."customer_city"
),

bottom_five AS (            -- five cities with lowest summed payments
    SELECT *
    FROM city_aggregates
    ORDER BY "total_payment" ASC NULLS LAST
    LIMIT 5
)

SELECT
    ROUND( AVG("total_payment"),          4 ) AS "avg_total_payment",
    ROUND( AVG("delivered_order_count"),  4 ) AS "avg_delivered_order_count"
FROM bottom_five;