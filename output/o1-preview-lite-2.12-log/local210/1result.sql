SELECT
  sub."hub_id",
  sub."hub_name"
FROM (
  SELECT
    h."hub_id",
    h."hub_name",
    SUM(CASE WHEN o."order_created_month" = 2 THEN 1 ELSE 0 END) AS "finished_orders_feb",
    SUM(CASE WHEN o."order_created_month" = 3 THEN 1 ELSE 0 END) AS "finished_orders_mar"
  FROM "orders" o
  JOIN "stores" s ON o."store_id" = s."store_id"
  JOIN "hubs" h ON s."hub_id" = h."hub_id"
  WHERE o."order_status" = 'FINISHED' AND o."order_created_year" = 2021 AND o."order_created_month" IN (2, 3)
  GROUP BY h."hub_id", h."hub_name"
) AS sub
WHERE sub."finished_orders_feb" > 0 AND
      (sub."finished_orders_mar" - sub."finished_orders_feb") * 100.0 / sub."finished_orders_feb" > 20;