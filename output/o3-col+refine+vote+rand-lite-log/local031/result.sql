WITH delivered AS (
    SELECT 
        strftime('%Y', "order_purchase_timestamp") AS yr,
        strftime('%m', "order_purchase_timestamp") AS mn
    FROM   "olist_orders"
    WHERE  "order_status" = 'delivered'
      AND  strftime('%Y', "order_purchase_timestamp") IN ('2016','2017','2018')
),
yearly_counts AS (      -- total delivered orders per year
    SELECT yr,
           COUNT(*) AS yr_cnt
    FROM   delivered
    GROUP  BY yr
),
min_year AS (           -- year with the fewest delivered orders
    SELECT yr
    FROM   yearly_counts
    ORDER  BY yr_cnt
    LIMIT  1
),
monthly_counts AS (     -- monthly delivered orders within that year
    SELECT mn,
           COUNT(*) AS mn_cnt
    FROM   delivered
    WHERE  yr = (SELECT yr FROM min_year)
    GROUP  BY mn
)
SELECT MAX(mn_cnt) AS "highest_monthly_volume"
FROM   monthly_counts;