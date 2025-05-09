WITH delivered AS (
    SELECT 
        order_id,
        STRFTIME('%Y', order_purchase_timestamp) AS yr,
        STRFTIME('%m', order_purchase_timestamp) AS mn
    FROM olist_orders
    WHERE order_status = 'delivered'
),
yearly_totals AS (
    SELECT 
        yr,
        COUNT(*) AS yr_orders
    FROM delivered
    WHERE yr IN ('2016','2017','2018')
    GROUP BY yr
),
min_year AS (
    SELECT yr
    FROM yearly_totals
    ORDER BY yr_orders
    LIMIT 1
),
monthly_totals AS (
    SELECT 
        mn,
        COUNT(*) AS mn_orders
    FROM delivered
    WHERE yr = (SELECT yr FROM min_year)
    GROUP BY mn
)
SELECT 
    MAX(mn_orders) AS highest_monthly_delivered_orders
FROM monthly_totals;