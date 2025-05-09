WITH order_payments_per_order AS (
    SELECT 
        "order_id",
        SUM("payment_value") AS order_payment
    FROM "olist_order_payments"
    GROUP BY "order_id"
),
delivered_orders AS (
    SELECT 
        o."order_id",
        c."customer_city"   AS city,
        op.order_payment
    FROM "olist_orders"            AS o
    JOIN order_payments_per_order  AS op ON op."order_id" = o."order_id"
    JOIN "olist_customers"         AS c  ON c."customer_id" = o."customer_id"
    WHERE o."order_status" = 'delivered'
),
city_totals AS (
    SELECT
        city,
        SUM(order_payment) AS total_payments,
        COUNT(*)           AS delivered_orders
    FROM delivered_orders
    GROUP BY city
),
five_lowest AS (
    SELECT *
    FROM city_totals
    ORDER BY total_payments ASC, city ASC
    LIMIT 5
)
SELECT 
    printf('%.4f', AVG(total_payments))       AS avg_total_payment,
    printf('%.4f', AVG(delivered_orders))     AS avg_total_delivered_order_count
FROM five_lowest;