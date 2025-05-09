WITH annual AS (
    SELECT substr(order_purchase_timestamp,1,4) AS year,
           COUNT(*) AS delivered_orders
    FROM olist_orders
    WHERE order_status = 'delivered'
      AND substr(order_purchase_timestamp,1,4) IN ('2016','2017','2018')
    GROUP BY substr(order_purchase_timestamp,1,4)
),
lowest AS (
    SELECT year
    FROM annual
    ORDER BY delivered_orders
    LIMIT 1
),
monthly AS (
    SELECT substr(order_purchase_timestamp,1,7) AS year_month,
           COUNT(*) AS delivered_orders
    FROM olist_orders
    WHERE order_status = 'delivered'
      AND substr(order_purchase_timestamp,1,4) = (SELECT year FROM lowest)
    GROUP BY substr(order_purchase_timestamp,1,7)
)
SELECT MAX(delivered_orders) AS highest_monthly_delivered_orders_volume
FROM monthly;