WITH delivered AS (
    SELECT 
        order_id,
        substr(order_purchase_timestamp, 1, 4) AS year,
        substr(order_purchase_timestamp, 6, 2) AS month
    FROM olist_orders
    WHERE order_status = 'delivered'
      AND substr(order_purchase_timestamp, 1, 4) IN ('2016','2017','2018')
),
annual AS (
    SELECT 
        year,
        COUNT(*) AS annual_count
    FROM delivered
    GROUP BY year
),
lowest_year AS (
    SELECT year
    FROM annual
    ORDER BY annual_count ASC, year
    LIMIT 1
),
monthly AS (
    SELECT 
        d.year,
        d.month,
        COUNT(*) AS monthly_count
    FROM delivered d
    JOIN lowest_year ly ON d.year = ly.year
    GROUP BY d.year, d.month
)
SELECT MAX(monthly_count) AS highest_monthly_delivered_orders
FROM monthly;