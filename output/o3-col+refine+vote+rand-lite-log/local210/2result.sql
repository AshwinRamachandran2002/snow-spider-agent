WITH feb AS (
    SELECT s."hub_id",
           COUNT(*) AS "feb_orders"
    FROM   "orders" o
    JOIN   "stores" s ON s."store_id" = o."store_id"
    WHERE  o."order_status"       = 'FINISHED'
      AND  o."order_created_month" = 2          -- February
    GROUP BY s."hub_id"
),
mar AS (
    SELECT s."hub_id",
           COUNT(*) AS "mar_orders"
    FROM   "orders" o
    JOIN   "stores" s ON s."store_id" = o."store_id"
    WHERE  o."order_status"       = 'FINISHED'
      AND  o."order_created_month" = 3          -- March
    GROUP BY s."hub_id"
)
SELECT   h."hub_name"
FROM     feb
JOIN     mar  ON mar."hub_id" = feb."hub_id"
JOIN     "hubs" h ON h."hub_id" = feb."hub_id"
WHERE    feb."feb_orders" > 0
  AND    100.0 * (mar."mar_orders" - feb."feb_orders") / feb."feb_orders" > 20;