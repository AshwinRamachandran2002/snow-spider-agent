WITH delivered AS (
    SELECT
        "order_id",
        TO_DATE("order_purchase_timestamp") AS purchase_date
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
    WHERE "order_status" = 'delivered'
      AND "order_purchase_timestamp" IS NOT NULL
      AND EXTRACT(year FROM TO_DATE("order_purchase_timestamp")) IN (2016, 2017, 2018)
),
yearly AS (
    SELECT
        EXTRACT(year FROM purchase_date) AS yr,
        COUNT(DISTINCT "order_id") AS orders_year
    FROM delivered
    GROUP BY yr
),
lowest_year AS (
    SELECT yr
    FROM (
        SELECT
            yr,
            orders_year,
            ROW_NUMBER() OVER (ORDER BY orders_year ASC) AS rn
        FROM yearly
    )
    WHERE rn = 1
),
monthly AS (
    SELECT
        DATE_TRUNC('month', purchase_date) AS month_start,
        COUNT(DISTINCT "order_id") AS orders_month
    FROM delivered
    WHERE EXTRACT(year FROM purchase_date) = (SELECT yr FROM lowest_year)
    GROUP BY month_start
)
SELECT MAX(orders_month) AS highest_monthly_delivered_orders_volume
FROM monthly;