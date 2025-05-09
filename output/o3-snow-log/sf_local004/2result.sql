WITH "ORDER_PAYMENTS_AGG" AS (          -- payment value per order
    SELECT
        "order_id",
        SUM("payment_value") AS "order_payment"
    FROM E_COMMERCE.E_COMMERCE."ORDER_PAYMENTS"
    GROUP BY "order_id"
), 
"ORDERS_WITH_PAYMENT" AS (              -- join orders to their payment totals
    SELECT
        o."customer_id",
        o."order_id",
        TO_TIMESTAMP(o."order_purchase_timestamp") AS "purchase_ts",
        p."order_payment"
    FROM E_COMMERCE.E_COMMERCE."ORDERS" o
    JOIN "ORDER_PAYMENTS_AGG"           p ON o."order_id" = p."order_id"
), 
"CUSTOMER_STATS" AS (                   -- metrics per customer
    SELECT
        "customer_id",
        COUNT(DISTINCT "order_id")                           AS "number_of_orders",
        AVG("order_payment")                                 AS "avg_payment_per_order",
        DATEDIFF('day',
                 MIN("purchase_ts"),
                 MAX("purchase_ts"))                         AS "days_span"
    FROM "ORDERS_WITH_PAYMENT"
    GROUP BY "customer_id"
), 
"CUSTOMER_FINAL" AS (                   -- apply lifespan rule
    SELECT
        "customer_id",
        "number_of_orders",
        "avg_payment_per_order",
        CASE
             WHEN "days_span" < 7 THEN 1.0
             ELSE  "days_span" / 7.0
        END                                             AS "customer_lifespan_weeks"
    FROM "CUSTOMER_STATS"
)
SELECT
    "customer_id",
    "number_of_orders",
    ROUND("avg_payment_per_order",     4) AS "avg_payment_per_order",
    ROUND("customer_lifespan_weeks",   4) AS "customer_lifespan_weeks"
FROM "CUSTOMER_FINAL"
ORDER BY "avg_payment_per_order" DESC NULLS LAST
LIMIT 3;