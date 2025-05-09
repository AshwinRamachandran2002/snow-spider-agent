WITH delivered AS (
    SELECT 
        substr("order_purchase_timestamp",1,4) AS year,
        substr("order_purchase_timestamp",1,7) AS year_month
    FROM "olist_orders"
    WHERE "order_status" = 'delivered'
      AND substr("order_purchase_timestamp",1,4) IN ('2016','2017','2018')
),
lowest_year AS (
    SELECT year
    FROM   delivered
    GROUP  BY year
    ORDER  BY COUNT(*)          -- fewest delivered orders
    LIMIT 1
),
monthly_totals AS (
    SELECT 
        year_month,
        COUNT(*) AS monthly_delivered_orders
    FROM delivered
    WHERE year = (SELECT year FROM lowest_year)
    GROUP BY year_month
)
SELECT monthly_delivered_orders
FROM   monthly_totals
ORDER  BY monthly_delivered_orders DESC
LIMIT 1;