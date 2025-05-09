WITH delivered_stats AS (
    SELECT  c."customer_unique_id",
            COUNT(o."order_id")            AS delivered_orders,
            AVG(p."payment_value")         AS avg_payment
    FROM    "olist_orders"          AS o
    JOIN    "olist_customers"       AS c ON o."customer_id" = c."customer_id"
    JOIN    "olist_order_payments"  AS p ON o."order_id"    = p."order_id"
    WHERE   o."order_status" = 'delivered'
    GROUP BY c."customer_unique_id"
),
customer_place AS (
    SELECT  "customer_unique_id",
            MIN("customer_city")   AS customer_city,
            MIN("customer_state")  AS customer_state
    FROM    "olist_customers"
    GROUP BY "customer_unique_id"
)
SELECT  ds."customer_unique_id",
        ds.delivered_orders,
        ROUND(ds.avg_payment, 4)   AS avg_payment_value,
        cp.customer_city,
        cp.customer_state
FROM    delivered_stats  AS ds
JOIN    customer_place   AS cp USING ("customer_unique_id")
ORDER BY ds.delivered_orders DESC
LIMIT 3;