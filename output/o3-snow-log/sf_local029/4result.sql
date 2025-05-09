WITH delivered_orders AS (
    SELECT
        "order_id",
        "customer_id"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS"
    WHERE "order_status" = 'delivered'
),
payments_per_order AS (
    SELECT
        "order_id",
        SUM("payment_value") AS total_payment_value
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS"
    GROUP BY "order_id"
),
orders_with_payment AS (
    SELECT
        d."customer_id",
        d."order_id",
        COALESCE(p.total_payment_value, 0) AS total_payment_value
    FROM delivered_orders d
    LEFT JOIN payments_per_order p
           ON d."order_id" = p."order_id"
),
customer_lookup AS (
    SELECT
        "customer_id",
        "customer_unique_id",
        "customer_city",
        "customer_state"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_CUSTOMERS"
),
customer_stats AS (
    SELECT
        cl."customer_unique_id",
        COUNT(DISTINCT o."order_id")                                AS num_delivered_orders,
        AVG(o.total_payment_value)                                  AS avg_payment_value,
        MIN(cl."customer_city")                                     AS "customer_city",
        MIN(cl."customer_state")                                    AS "customer_state"
    FROM orders_with_payment o
    JOIN customer_lookup  cl
          ON o."customer_id" = cl."customer_id"
    GROUP BY cl."customer_unique_id"
),
ranked_customers AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY num_delivered_orders DESC NULLS LAST) AS rn
    FROM customer_stats
)
SELECT
    "customer_unique_id",
    ROUND(avg_payment_value, 4) AS avg_payment_value,
    "customer_city",
    "customer_state"
FROM ranked_customers
WHERE rn <= 3
ORDER BY num_delivered_orders DESC NULLS LAST, "customer_unique_id";