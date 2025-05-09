WITH delivered_orders AS (
    SELECT 
        TO_TIMESTAMP("order_purchase_timestamp") AS purchase_ts
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
    WHERE "order_status" = 'delivered'
      AND TO_DATE("order_purchase_timestamp") BETWEEN '2016-01-01' AND '2018-12-31'
),
annual_counts AS (
    SELECT 
        EXTRACT(year FROM purchase_ts) AS yr,
        COUNT(*)                         AS delivered_orders
    FROM delivered_orders
    GROUP BY yr
    HAVING yr IN (2016, 2017, 2018)
),
lowest_year AS (
    SELECT yr
    FROM annual_counts
    ORDER BY delivered_orders ASC NULLS LAST
    LIMIT 1
),
monthly_counts AS (
    SELECT 
        EXTRACT(year  FROM purchase_ts) AS yr,
        EXTRACT(month FROM purchase_ts) AS mo,
        COUNT(*)                        AS delivered_orders
    FROM delivered_orders
    GROUP BY yr, mo
),
ranked_months AS (
    SELECT 
        mo,
        delivered_orders,
        ROW_NUMBER() OVER (ORDER BY delivered_orders DESC) AS rn
    FROM monthly_counts
    WHERE yr = (SELECT yr FROM lowest_year)
)
SELECT delivered_orders AS "highest_monthly_delivered_orders"
FROM ranked_months
WHERE rn = 1;