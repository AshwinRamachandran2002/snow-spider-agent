WITH delivered AS (              -- all delivered orders with extracted year & month
    SELECT "order_id",
           substr("order_purchase_timestamp",1,4) AS year,
           substr("order_purchase_timestamp",6,2) AS month
    FROM   "olist_orders"
    WHERE  "order_status" = 'delivered'
),
yearly_totals AS (               -- total delivered orders per year
    SELECT year,
           COUNT(DISTINCT order_id) AS yearly_count
    FROM   delivered
    GROUP  BY year
),
lowest_year AS (                 -- the year with the fewest delivered orders
    SELECT year
    FROM   yearly_totals
    ORDER  BY yearly_count ASC
    LIMIT 1
),
monthly_totals AS (              -- monthly delivered-order counts
    SELECT year,
           month,
           COUNT(DISTINCT order_id) AS monthly_count
    FROM   delivered
    GROUP  BY year, month
)
SELECT MAX(monthly_count) AS highest_monthly_volume_lowest_year
FROM   monthly_totals
WHERE  year = (SELECT year FROM lowest_year);