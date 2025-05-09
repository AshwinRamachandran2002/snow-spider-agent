WITH delivered_orders AS (
    SELECT
        TO_DATE("order_purchase_timestamp")                               AS purchase_date
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
    WHERE "order_status" = 'delivered'
      AND "order_purchase_timestamp" IS NOT NULL
      AND EXTRACT(YEAR FROM TO_DATE("order_purchase_timestamp")) IN (2016, 2017, 2018)
),
annual_delivered AS (
    SELECT
        EXTRACT(YEAR FROM purchase_date)                                  AS yr,
        COUNT(*)                                                          AS annual_orders
    FROM delivered_orders
    GROUP BY yr
),
min_year AS (
    SELECT yr
    FROM annual_delivered
    QUALIFY ROW_NUMBER() OVER (ORDER BY annual_orders ASC) = 1
),
monthly_delivered AS (
    SELECT
        EXTRACT(YEAR  FROM purchase_date)                                 AS yr,
        EXTRACT(MONTH FROM purchase_date)                                 AS mn,
        COUNT(*)                                                          AS monthly_orders
    FROM delivered_orders
    WHERE EXTRACT(YEAR FROM purchase_date) = (SELECT yr FROM min_year)
    GROUP BY yr, mn
)
SELECT
    MAX(monthly_orders)                                                   AS highest_monthly_delivered_orders
FROM monthly_delivered;