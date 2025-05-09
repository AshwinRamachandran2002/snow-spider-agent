WITH delivered AS (
    SELECT order_id,
           strftime('%Y', order_purchase_timestamp) AS yr,
           strftime('%m', order_purchase_timestamp) AS mo
    FROM olist_orders
    WHERE order_status = 'delivered'
      AND strftime('%Y', order_purchase_timestamp) IN ('2016','2017','2018')
),
year_totals AS (
    SELECT yr,
           COUNT(*) AS annual_cnt
    FROM delivered
    GROUP BY yr
),
lowest_year AS (
    SELECT yr
    FROM year_totals
    ORDER BY annual_cnt ASC, yr ASC
    LIMIT 1
),
month_totals AS (
    SELECT mo,
           COUNT(*) AS monthly_cnt
    FROM delivered
    WHERE yr = (SELECT yr FROM lowest_year)
    GROUP BY mo
)
SELECT MAX(monthly_cnt) AS highest_monthly_volume
FROM month_totals;