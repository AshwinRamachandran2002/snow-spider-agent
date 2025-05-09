WITH delivered_orders AS (   /* all delivered orders between 2016-2018 */
    SELECT
        TO_DATE("order_purchase_timestamp")           AS purchase_date
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
    WHERE "order_status" = 'delivered'
      AND YEAR(TO_DATE("order_purchase_timestamp")) IN (2016, 2017, 2018)
), yearly_totals AS (        /* annual delivered-order volumes          */
    SELECT
        YEAR(purchase_date)                    AS yr,
        COUNT(*)                               AS year_orders
    FROM delivered_orders
    GROUP BY YEAR(purchase_date)
), lowest_year AS (          /* year that has the lowest annual volume  */
    SELECT yr
    FROM yearly_totals
    ORDER BY year_orders ASC
    LIMIT 1
), monthly_totals AS (       /* monthly volumes inside the lowest year  */
    SELECT
        YEAR(purchase_date)                    AS yr,
        MONTH(purchase_date)                   AS mn,
        COUNT(*)                               AS month_orders
    FROM delivered_orders
    WHERE YEAR(purchase_date) = (SELECT yr FROM lowest_year)
    GROUP BY YEAR(purchase_date), MONTH(purchase_date)
)
SELECT
    MAX(month_orders) AS highest_monthly_delivered_orders_volume
FROM monthly_totals;