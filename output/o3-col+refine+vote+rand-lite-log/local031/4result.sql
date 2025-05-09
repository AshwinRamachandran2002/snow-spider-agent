WITH year_counts AS (
    SELECT SUBSTR("order_purchase_timestamp",1,4) AS year,
           COUNT(*) AS delivered_orders
    FROM "olist_orders"
    WHERE "order_status" = 'delivered'
      AND SUBSTR("order_purchase_timestamp",1,4) IN ('2016','2017','2018')
    GROUP BY year
),
min_year AS (
    SELECT year
    FROM year_counts
    ORDER BY delivered_orders
    LIMIT 1
),
monthly_counts AS (
    SELECT SUBSTR("order_purchase_timestamp",6,2) AS month,
           COUNT(*) AS delivered_orders
    FROM "olist_orders"
    WHERE "order_status" = 'delivered'
      AND SUBSTR("order_purchase_timestamp",1,4) = (SELECT year FROM min_year)
    GROUP BY month
)
SELECT MAX(delivered_orders) AS highest_monthly_delivered_orders
FROM monthly_counts;