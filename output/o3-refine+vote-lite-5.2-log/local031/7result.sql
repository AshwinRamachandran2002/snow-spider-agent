WITH delivered AS (
    SELECT
        order_id,
        substr(order_purchase_timestamp, 1, 4)  AS order_year,
        substr(order_purchase_timestamp, 1, 7)  AS order_year_month
    FROM olist_orders
    WHERE order_status = 'delivered'
      AND substr(order_purchase_timestamp, 1, 4) IN ('2016', '2017', '2018')
),
annual_counts AS (
    SELECT
        order_year AS year,
        COUNT(*)   AS year_count
    FROM delivered
    GROUP BY order_year
),
min_year AS (
    SELECT year
    FROM annual_counts
    WHERE year_count = (SELECT MIN(year_count) FROM annual_counts)
    LIMIT 1
),
month_counts AS (
    SELECT
        order_year_month,
        COUNT(*) AS month_count
    FROM delivered
    WHERE order_year = (SELECT year FROM min_year)
    GROUP BY order_year_month
)
SELECT MAX(month_count) AS highest_monthly_delivered_orders_volume
FROM month_counts;