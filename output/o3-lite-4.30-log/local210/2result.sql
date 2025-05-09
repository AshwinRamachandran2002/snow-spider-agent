WITH feb AS (
    SELECT h."hub_id",
           COUNT(*) AS "feb_qty"
    FROM "orders" o
    JOIN "stores" s ON s."store_id" = o."store_id"
    JOIN "hubs"   h ON h."hub_id"   = s."hub_id"
    WHERE o."order_status" = 'FINISHED'
      AND o."order_created_month" = 2           -- February
    GROUP BY h."hub_id"
),
mar AS (
    SELECT h."hub_id",
           COUNT(*) AS "mar_qty"
    FROM "orders" o
    JOIN "stores" s ON s."store_id" = o."store_id"
    JOIN "hubs"   h ON h."hub_id"   = s."hub_id"
    WHERE o."order_status" = 'FINISHED'
      AND o."order_created_month" = 3           -- March
    GROUP BY h."hub_id"
)
SELECT h."hub_name",
       ROUND((mar."mar_qty" - feb."feb_qty") * 1.0 / feb."feb_qty" * 100, 4) AS "percent_increase"
FROM   "hubs" h
JOIN   feb ON feb."hub_id" = h."hub_id"
JOIN   mar ON mar."hub_id" = h."hub_id"
WHERE  mar."mar_qty" > feb."feb_qty" * 1.20      -- >20% growth
ORDER  BY "percent_increase" DESC, h."hub_name";