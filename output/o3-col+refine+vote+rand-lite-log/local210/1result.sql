WITH
-- February finished-order count per hub
feb AS (
  SELECT s."hub_id",
         COUNT(*) AS "feb_finished_orders"
  FROM   "orders" o
  JOIN   "stores" s ON o."store_id" = s."store_id"
  WHERE  o."order_status"       = 'FINISHED'
    AND  o."order_created_month" = 2
  GROUP BY s."hub_id"
),
-- March finished-order count per hub
mar AS (
  SELECT s."hub_id",
         COUNT(*) AS "mar_finished_orders"
  FROM   "orders" o
  JOIN   "stores" s ON o."store_id" = s."store_id"
  WHERE  o."order_status"       = 'FINISHED'
    AND  o."order_created_month" = 3
  GROUP BY s."hub_id"
),
-- Combine the two months and compute growth ratio
growth AS (
  SELECT f."hub_id",
         f."feb_finished_orders",
         m."mar_finished_orders",
         ROUND(
           (m."mar_finished_orders" - f."feb_finished_orders") * 1.0
           / f."feb_finished_orders", 4
         ) AS "growth_ratio"
  FROM   feb f
  JOIN   mar m ON f."hub_id" = m."hub_id"
  WHERE  f."feb_finished_orders" > 0
)
-- Return hubs whose March volume is >20 % higher than February
SELECT   g."hub_id",
         h."hub_name",
         g."feb_finished_orders",
         g."mar_finished_orders",
         g."growth_ratio"
FROM     growth g
JOIN     "hubs" h ON g."hub_id" = h."hub_id"
WHERE    g."growth_ratio" > 0.20
ORDER BY g."growth_ratio" DESC;