WITH feb AS (
    SELECT h."hub_id",
           COUNT(*) AS cnt_feb
    FROM   "orders"  o
    JOIN   "stores"  s ON s."store_id" = o."store_id"
    JOIN   "hubs"    h ON h."hub_id"   = s."hub_id"
    WHERE  o."order_status"        = 'FINISHED'
      AND  o."order_created_year"  = 2021
      AND  o."order_created_month" = 2
    GROUP BY h."hub_id"
),
mar AS (
    SELECT h."hub_id",
           COUNT(*) AS cnt_mar
    FROM   "orders"  o
    JOIN   "stores"  s ON s."store_id" = o."store_id"
    JOIN   "hubs"    h ON h."hub_id"   = s."hub_id"
    WHERE  o."order_status"        = 'FINISHED'
      AND  o."order_created_year"  = 2021
      AND  o."order_created_month" = 3
    GROUP BY h."hub_id"
)
SELECT h."hub_id",
       h."hub_name"
FROM   feb
JOIN   mar ON mar."hub_id" = feb."hub_id"
JOIN   "hubs" h ON h."hub_id" = feb."hub_id"
WHERE  (mar.cnt_mar - feb.cnt_feb) * 100.0 / feb.cnt_feb > 20
ORDER  BY h."hub_id";