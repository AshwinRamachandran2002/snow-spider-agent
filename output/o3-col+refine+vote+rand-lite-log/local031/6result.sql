WITH delivered AS (
    SELECT order_purchase_timestamp
    FROM olist_orders
    WHERE order_status = 'delivered'
      AND strftime('%Y', order_purchase_timestamp) IN ('2016','2017','2018')
),
lowest_year AS (
    SELECT strftime('%Y', order_purchase_timestamp) AS yr
    FROM delivered
    GROUP BY yr
    ORDER BY COUNT(*) ASC
    LIMIT 1
),
monthly_totals AS (
    SELECT strftime('%m', d.order_purchase_timestamp) AS mo,
           COUNT(*) AS monthly_cnt
    FROM delivered d
    JOIN lowest_year ly
          ON strftime('%Y', d.order_purchase_timestamp) = ly.yr
    GROUP BY mo
)
SELECT MAX(monthly_cnt) AS highest_monthly_delivered_orders_volume
FROM monthly_totals;