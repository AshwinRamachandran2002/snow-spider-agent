WITH delivered AS (
    SELECT 
        order_id,
        strftime('%Y', order_delivered_customer_date) AS yr,
        strftime('%m', order_delivered_customer_date) AS mo
    FROM olist_orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND strftime('%Y', order_delivered_customer_date) IN ('2016','2017','2018')
),
year_totals AS (
    SELECT 
        yr,
        COUNT(*) AS yr_cnt
    FROM delivered
    GROUP BY yr
),
min_year AS (
    SELECT yr
    FROM year_totals
    ORDER BY yr_cnt
    LIMIT 1
),
month_totals AS (
    SELECT 
        mo,
        COUNT(*) AS mo_cnt
    FROM delivered
    WHERE yr = (SELECT yr FROM min_year)
    GROUP BY mo
)
SELECT MAX(mo_cnt) AS highest_monthly_volume
FROM month_totals;