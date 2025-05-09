WITH delivered AS (
    SELECT
        "order_id",
        TO_TIMESTAMP("order_purchase_timestamp") AS purchase_ts
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS"
    WHERE "order_status" = 'delivered'
      AND YEAR(TO_TIMESTAMP("order_purchase_timestamp")) IN (2016, 2017, 2018)
), annual AS (
    SELECT
        YEAR(purchase_ts) AS yr,
        COUNT(*)           AS annual_delivered
    FROM delivered
    GROUP BY yr
), lowest_year AS (
    SELECT yr
    FROM annual
    ORDER BY annual_delivered ASC NULLS LAST
    LIMIT 1
), monthly AS (
    SELECT
        YEAR(purchase_ts)  AS yr,
        MONTH(purchase_ts) AS mn,
        COUNT(*)           AS monthly_delivered
    FROM delivered
    GROUP BY yr, mn
)
SELECT
    MAX(monthly_delivered) AS highest_monthly_volume
FROM monthly
WHERE yr = (SELECT yr FROM lowest_year);