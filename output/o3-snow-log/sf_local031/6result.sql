WITH delivered_orders AS (
    SELECT
        "order_id",
        TO_DATE("order_purchase_timestamp")           AS purchase_date
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS"
    WHERE "order_status" = 'delivered'
      AND DATE_PART(year, TO_DATE("order_purchase_timestamp")) IN (2016, 2017, 2018)
),
annual_totals AS (
    SELECT
        DATE_PART(year, purchase_date)               AS yr,
        COUNT(*)                                     AS annual_cnt
    FROM delivered_orders
    GROUP BY yr
),
lowest_year AS (
    SELECT yr
    FROM annual_totals
    ORDER BY annual_cnt ASC
    LIMIT 1
),
monthly_totals AS (
    SELECT
        DATE_PART(year, purchase_date)               AS yr,
        DATE_PART(month, purchase_date)              AS mn,
        COUNT(*)                                     AS monthly_cnt
    FROM delivered_orders
    WHERE DATE_PART(year, purchase_date) = (SELECT yr FROM lowest_year)
    GROUP BY yr, mn
)
SELECT
    MAX(monthly_cnt) AS "HIGHEST_MONTHLY_DELIVERED_ORDERS_VOLUME"
FROM monthly_totals;