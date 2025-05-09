WITH delivered_orders AS (
    SELECT
        date("order_purchase_timestamp") AS purchase_date
    FROM "olist_orders"
    WHERE "order_status" = 'delivered'
),
yearly_totals AS (
    SELECT
        strftime('%Y', purchase_date) AS year,
        COUNT(*) AS orders_in_year
    FROM delivered_orders
    WHERE strftime('%Y', purchase_date) IN ('2016', '2017', '2018')
    GROUP BY year
),
year_with_lowest_total AS (
    SELECT year
    FROM yearly_totals
    ORDER BY orders_in_year ASC, year
    LIMIT 1
),
monthly_totals AS (
    SELECT
        strftime('%Y-%m', purchase_date) AS year_month,
        COUNT(*) AS orders_in_month
    FROM delivered_orders
    WHERE strftime('%Y', purchase_date) = (SELECT year FROM year_with_lowest_total)
    GROUP BY year_month
)
SELECT MAX(orders_in_month) AS highest_monthly_delivered_orders_volume
FROM monthly_totals;