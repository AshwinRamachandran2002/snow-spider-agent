WITH delivered_orders AS (
    /* keep only successfully parsed delivered dates of delivered orders */
    SELECT
        CAST(TRY_TO_TIMESTAMP("order_delivered_customer_date") AS DATE) AS delivered_date
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
    WHERE "order_status" = 'delivered'
          AND TRY_TO_TIMESTAMP("order_delivered_customer_date") IS NOT NULL
),
filtered_years AS (
    /* restrict to the required years */
    SELECT
        delivered_date
    FROM delivered_orders
    WHERE EXTRACT(year FROM delivered_date) IN (2016, 2017, 2018)
),
month_year_totals AS (
    /* count delivered orders per month and year */
    SELECT
        EXTRACT(year  FROM delivered_date)           AS yr,
        EXTRACT(month FROM delivered_date)           AS mn,
        TO_CHAR(delivered_date, 'Mon')               AS month_name,
        COUNT(*)                                     AS orders_cnt
    FROM filtered_years
    GROUP BY yr, mn, month_name
)
SELECT
    month_name                                         AS "month",
    SUM(CASE WHEN yr = 2016 THEN orders_cnt ELSE 0 END) AS "2016",
    SUM(CASE WHEN yr = 2017 THEN orders_cnt ELSE 0 END) AS "2017",
    SUM(CASE WHEN yr = 2018 THEN orders_cnt ELSE 0 END) AS "2018"
FROM month_year_totals
GROUP BY mn, month_name
ORDER BY mn;