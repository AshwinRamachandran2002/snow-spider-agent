WITH delivered_orders AS (   -- delivered orders with their customers' cities
    SELECT
        o."order_id",
        c."customer_city"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS          o
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_CUSTOMERS       c
          ON o."customer_id" = c."customer_id"
    WHERE o."order_status" = 'delivered'
),

order_payments AS (          -- total payment per order (sums all payment rows of the order)
    SELECT
        p."order_id",
        SUM(p."payment_value") AS order_payment
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_PAYMENTS  p
    GROUP BY p."order_id"
),

city_aggregates AS (         -- totals by city
    SELECT
        d."customer_city"                                    AS city,
        SUM(COALESCE(op.order_payment, 0))                   AS total_payments,
        COUNT(DISTINCT d."order_id")                         AS order_count
    FROM delivered_orders d
    LEFT JOIN order_payments op
           ON d."order_id" = op."order_id"
    GROUP BY d."customer_city"
),

lowest_five_cities AS (      -- five cities with the smallest summed payments
    SELECT *
    FROM city_aggregates
    ORDER BY total_payments ASC NULLS LAST
    LIMIT 5
)

SELECT
    ROUND(AVG(total_payments), 4)  AS avg_total_payments,
    ROUND(AVG(order_count),   4)   AS avg_order_count
FROM lowest_five_cities;