WITH delivered_orders AS (
    /* all delivered orders in 2016-2018 */
    SELECT 
        TO_TIMESTAMP("order_purchase_timestamp")  AS purchase_ts
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS"
    WHERE "order_status" = 'delivered'
      AND TO_CHAR(TO_TIMESTAMP("order_purchase_timestamp"), 'YYYY') IN ('2016','2017','2018')
),

annual_totals AS (
    /* yearly delivered-orders volume */
    SELECT 
        EXTRACT(year FROM purchase_ts) AS yr,
        COUNT(*)                       AS annual_orders
    FROM delivered_orders
    GROUP BY yr
),

lowest_year AS (
    /* the year with the lowest delivered-orders volume */
    SELECT yr
    FROM annual_totals
    ORDER BY annual_orders ASC, yr
    LIMIT 1
),

monthly_totals AS (
    /* monthly volumes inside that lowest year */
    SELECT
        EXTRACT(month FROM purchase_ts) AS mn,
        COUNT(*)                        AS monthly_orders
    FROM delivered_orders
    WHERE EXTRACT(year FROM purchase_ts) = (SELECT yr FROM lowest_year)
    GROUP BY mn
)

SELECT 
    MAX(monthly_orders) AS highest_monthly_delivered_orders_volume
FROM monthly_totals;