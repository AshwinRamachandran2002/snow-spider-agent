WITH yearly AS (
    SELECT substr("order_purchase_timestamp",1,4) AS year,
           COUNT(*) AS delivered_orders
    FROM   "olist_orders"
    WHERE  "order_status" = 'delivered'
      AND  substr("order_purchase_timestamp",1,4) IN ('2016','2017','2018')
    GROUP  BY year
), lowest_year AS (
    SELECT year
    FROM   yearly
    ORDER  BY delivered_orders
    LIMIT  1
), monthly AS (
    SELECT substr("order_purchase_timestamp",1,7) AS year_month,
           COUNT(*) AS delivered_orders
    FROM   "olist_orders"
    WHERE  "order_status" = 'delivered'
      AND  substr("order_purchase_timestamp",1,4) = (SELECT year FROM lowest_year)
    GROUP  BY year_month
)
SELECT MAX(delivered_orders) AS highest_monthly_volume
FROM   monthly;