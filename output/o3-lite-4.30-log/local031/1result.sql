WITH yearly AS (
    SELECT substr(order_purchase_timestamp,1,4) AS yr,
           COUNT(DISTINCT order_id) AS delivered_orders
    FROM olist_orders
    WHERE order_status = 'delivered'
      AND substr(order_purchase_timestamp,1,4) IN ('2016','2017','2018')
    GROUP BY yr
),
min_year AS (
    SELECT yr
    FROM yearly
    ORDER BY delivered_orders
    LIMIT 1
),
monthly AS (
    SELECT substr(order_purchase_timestamp,1,7) AS ym,
           COUNT(DISTINCT order_id) AS delivered_orders
    FROM olist_orders
    WHERE order_status = 'delivered'
      AND substr(order_purchase_timestamp,1,4) = (SELECT yr FROM min_year)
    GROUP BY ym
)
SELECT MAX(delivered_orders) AS highest_monthly_delivered_orders_volume
FROM monthly;