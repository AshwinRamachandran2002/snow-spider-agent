WITH "PAYMENTS_SUM" AS (   -- total paid per order
    SELECT 
        "order_id",
        SUM("payment_value") AS "total_payment_value"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS"
    GROUP BY "order_id"
),
"DELIVERED_ORDERS" AS (    -- only delivered orders + their payments
    SELECT 
        o."order_id",
        o."customer_id",
        ps."total_payment_value"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS" o
    LEFT JOIN "PAYMENTS_SUM" ps
           ON o."order_id" = ps."order_id"
    WHERE o."order_status" = 'delivered'
),
"CUSTOMER_ORDERS" AS (     -- add customer info
    SELECT
        c."customer_unique_id",
        c."customer_city",
        c."customer_state",
        d."order_id",
        d."total_payment_value"
    FROM "DELIVERED_ORDERS" d
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_CUSTOMERS" c
         ON d."customer_id" = c."customer_id"
),
"CUSTOMER_AGG" AS (        -- delivered-order count & avg payment per customer
    SELECT
        "customer_unique_id",
        COUNT("order_id")          AS "delivered_order_count",
        AVG("total_payment_value") AS "avg_payment_value"
    FROM "CUSTOMER_ORDERS"
    GROUP BY "customer_unique_id"
),
"CITY_STATE_BEST" AS (     -- most-common city/state per customer
    SELECT
        "customer_unique_id",
        "customer_city",
        "customer_state"
    FROM (
        SELECT
            "customer_unique_id",
            "customer_city",
            "customer_state",
            ROW_NUMBER() OVER (
                PARTITION BY "customer_unique_id" 
                ORDER BY COUNT(*) DESC, "customer_city"
            ) AS rn
        FROM "CUSTOMER_ORDERS"
        GROUP BY "customer_unique_id", "customer_city", "customer_state"
    )
    WHERE rn = 1
)
SELECT
    ca."customer_unique_id",
    ca."delivered_order_count",
    ca."avg_payment_value",
    cs."customer_city",
    cs."customer_state"
FROM "CUSTOMER_AGG"  ca
JOIN "CITY_STATE_BEST" cs
      ON ca."customer_unique_id" = cs."customer_unique_id"
ORDER BY ca."delivered_order_count" DESC NULLS LAST
LIMIT 3;