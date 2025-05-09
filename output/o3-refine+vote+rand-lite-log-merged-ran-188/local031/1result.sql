WITH delivered AS (
    SELECT
        "order_id",
        date("order_delivered_customer_date") AS delivered_date
    FROM "olist_orders"
    WHERE "order_status" = 'delivered'
      AND "order_delivered_customer_date" IS NOT NULL
),
year_counts AS (
    SELECT
        CAST(strftime('%Y', delivered_date) AS INTEGER) AS yr,
        COUNT(*) AS orders_year
    FROM delivered
    WHERE strftime('%Y', delivered_date) IN ('2016','2017','2018')
    GROUP BY yr
),
lowest_year AS (
    SELECT yr
    FROM year_counts
    ORDER BY orders_year ASC, yr                -- pick the year with the fewest delivered orders
    LIMIT 1
),
monthly_counts AS (
    SELECT
        CAST(strftime('%m', delivered_date) AS INTEGER) AS mn,
        COUNT(*) AS orders_month
    FROM delivered
    WHERE CAST(strftime('%Y', delivered_date) AS INTEGER) = (SELECT yr FROM lowest_year)
    GROUP BY mn
)
SELECT MAX(orders_month) AS highest_monthly_delivered_orders_volume
FROM monthly_counts;