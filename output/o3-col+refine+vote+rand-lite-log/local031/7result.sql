WITH annual AS (
    SELECT substr("order_purchase_timestamp",1,4)       AS "order_year",
           COUNT(*)                                     AS "delivered_orders"
    FROM   "olist_orders"
    WHERE  "order_status" = 'delivered'
      AND  substr("order_purchase_timestamp",1,4) IN ('2016','2017','2018')
    GROUP  BY "order_year"
),
lowest_year AS (
    SELECT "order_year"
    FROM   annual
    ORDER  BY "delivered_orders" ASC
    LIMIT 1
),
monthly AS (
    SELECT substr("order_purchase_timestamp",1,7)       AS "year_month",
           COUNT(*)                                     AS "monthly_cnt"
    FROM   "olist_orders"
    WHERE  "order_status" = 'delivered'
      AND  substr("order_purchase_timestamp",1,4) = (SELECT "order_year" FROM lowest_year)
    GROUP  BY "year_month"
)
SELECT MAX("monthly_cnt") AS "highest_monthly_volume_lowest_year"
FROM   monthly;