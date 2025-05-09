WITH delivered AS (
    SELECT
        order_id,
        strftime('%Y', order_purchase_timestamp) AS yr,
        strftime('%m', order_purchase_timestamp) AS mo
    FROM olist_orders
    WHERE order_status = 'delivered'
      AND strftime('%Y', order_purchase_timestamp) IN ('2016','2017','2018')
),
year_counts AS (
    SELECT
        yr,
        COUNT(*) AS year_orders
    FROM delivered
    GROUP BY yr
),
min_year AS (
    SELECT yr
    FROM year_counts
    ORDER BY year_orders ASC, yr
    LIMIT 1
),
monthly_counts AS (
    SELECT
        yr,
        mo,
        COUNT(*) AS month_orders
    FROM delivered
    WHERE yr = (SELECT yr FROM min_year)
    GROUP BY yr, mo
)
SELECT
    MAX(month_orders) AS highest_monthly_delivered_orders
FROM monthly_counts;