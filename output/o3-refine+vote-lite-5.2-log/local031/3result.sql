WITH delivered AS (
    SELECT
        order_id,
        substr(order_purchase_timestamp, 1, 4) AS yr,
        substr(order_purchase_timestamp, 6, 2) AS mo
    FROM olist_orders
    WHERE order_status = 'delivered'
      AND substr(order_purchase_timestamp, 1, 4) IN ('2016','2017','2018')
),
yearly AS (
    SELECT yr AS year, COUNT(*) AS yearly_cnt
    FROM delivered
    GROUP BY yr
),
min_year AS (
    SELECT year
    FROM yearly
    ORDER BY yearly_cnt ASC, year ASC
    LIMIT 1
),
monthly AS (
    SELECT
        yr,
        mo,
        COUNT(*) AS monthly_cnt
    FROM delivered
    WHERE yr = (SELECT year FROM min_year)
    GROUP BY yr, mo
)
SELECT MAX(monthly_cnt) AS highest_monthly_volume
FROM monthly;