WITH delivered_orders AS (
    SELECT
        "order_id",
        TO_TIMESTAMP("order_purchase_timestamp")  AS purchase_ts
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
    WHERE "order_status" = 'delivered'
      AND TO_TIMESTAMP("order_purchase_timestamp") >= '2016-01-01'
      AND TO_TIMESTAMP("order_purchase_timestamp") <  '2019-01-01'
),    
annual_delivered AS (
    SELECT
        EXTRACT(YEAR FROM purchase_ts)                AS order_year,
        COUNT(*)                                       AS annual_delivered_orders
    FROM delivered_orders
    GROUP BY order_year
),    
lowest_year AS (
    SELECT order_year
    FROM annual_delivered
    WHERE annual_delivered_orders = (
          SELECT MIN(annual_delivered_orders) FROM annual_delivered
    )
),    
monthly_delivered AS (
    SELECT
        EXTRACT(YEAR  FROM purchase_ts)               AS order_year,
        EXTRACT(MONTH FROM purchase_ts)               AS order_month,
        COUNT(*)                                      AS monthly_delivered_orders
    FROM delivered_orders
    WHERE EXTRACT(YEAR FROM purchase_ts) IN (SELECT order_year FROM lowest_year)
    GROUP BY order_year, order_month
)
SELECT MAX(monthly_delivered_orders) AS highest_monthly_delivered_orders
FROM monthly_delivered;