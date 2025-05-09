WITH delivered_payments AS (
    SELECT c."customer_unique_id",
           o."order_id",
           op."payment_value"
    FROM   "olist_orders"          AS o
    JOIN   "olist_order_payments"  AS op ON o."order_id"  = op."order_id"
    JOIN   "olist_customers"       AS c  ON o."customer_id" = c."customer_id"
    WHERE  o."order_status" = 'delivered'
),
agg AS (
    SELECT "customer_unique_id",
           COUNT(DISTINCT "order_id")        AS "delivered_orders",
           AVG("payment_value")              AS "avg_payment"
    FROM   delivered_payments
    GROUP  BY "customer_unique_id"
),
loc AS (
    SELECT "customer_unique_id",
           MIN("customer_city")  AS "city",
           MIN("customer_state") AS "state"
    FROM   "olist_customers"
    GROUP  BY "customer_unique_id"
)
SELECT a."customer_unique_id",
       a."delivered_orders",
       ROUND(a."avg_payment", 4) AS "avg_payment",
       l."city",
       l."state"
FROM   agg AS a
JOIN   loc AS l
       ON a."customer_unique_id" = l."customer_unique_id"
ORDER  BY a."delivered_orders" DESC,
         a."avg_payment"      DESC
LIMIT 3;