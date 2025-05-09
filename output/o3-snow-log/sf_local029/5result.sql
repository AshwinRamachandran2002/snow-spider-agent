WITH delivered_orders AS (   /* all delivered orders */
    SELECT 
        o."order_id",
        o."customer_id"
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDERS" o
    WHERE o."order_status" = 'delivered'
), 

order_payments AS (          /* total paid per order (sums installments) */
    SELECT 
        p."order_id",
        SUM(p."payment_value") AS order_payment_value
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_PAYMENTS" p
    GROUP BY p."order_id"
), 

order_customer_payments AS ( /* link delivered orders to customer_unique_id and payment */
    SELECT  
        d."order_id",
        c."customer_unique_id",
        COALESCE(op.order_payment_value, 0) AS order_payment_value
    FROM delivered_orders      d
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_CUSTOMERS" c
           ON d."customer_id" = c."customer_id"
    LEFT JOIN order_payments   op
           ON d."order_id" = op."order_id"
), 

customer_stats AS (          /* delivered-order count and avg payment per unique customer */
    SELECT
        "customer_unique_id",
        COUNT(*)                       AS delivered_order_cnt,
        AVG(order_payment_value)       AS avg_payment_value
    FROM order_customer_payments
    GROUP BY "customer_unique_id"
), 

customer_locations AS (      /* pick one city/state per unique customer */
    SELECT
        "customer_unique_id",
        "customer_city",
        "customer_state",
        ROW_NUMBER() OVER (PARTITION BY "customer_unique_id" ORDER BY "customer_id") AS rn
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_CUSTOMERS"
), 

top_customers AS (           /* join stats with location and keep top 3 by delivered orders */
    SELECT
        s."customer_unique_id",
        s.delivered_order_cnt,
        s.avg_payment_value,
        l."customer_city",
        l."customer_state"
    FROM customer_stats      s
    JOIN customer_locations  l
          ON s."customer_unique_id" = l."customer_unique_id"
    WHERE l.rn = 1
    ORDER BY s.delivered_order_cnt DESC NULLS LAST
    LIMIT 3
)

SELECT
    "customer_unique_id",
    delivered_order_cnt,
    ROUND(avg_payment_value, 4) AS avg_payment_value,
    "customer_city",
    "customer_state"
FROM top_customers
ORDER BY delivered_order_cnt DESC NULLS LAST;