SELECT
    h."hub_id",
    h."hub_name",
    SUM(CASE WHEN o."order_created_month" = 2 THEN 1 ELSE 0 END) AS "feb_finished_orders",
    SUM(CASE WHEN o."order_created_month" = 3 THEN 1 ELSE 0 END) AS "mar_finished_orders",
    ROUND(
        (SUM(CASE WHEN o."order_created_month" = 3 THEN 1 ELSE 0 END) -
         SUM(CASE WHEN o."order_created_month" = 2 THEN 1 ELSE 0 END)) * 100.0 /
         SUM(CASE WHEN o."order_created_month" = 2 THEN 1 ELSE 0 END), 2
    ) AS "perc_change"
FROM "orders"  AS o
JOIN "stores"  AS s ON o."store_id" = s."store_id"
JOIN "hubs"    AS h ON s."hub_id" = h."hub_id"
WHERE o."order_status" = 'FINISHED'
  AND o."order_created_year" = 2021
  AND o."order_created_month" IN (2, 3)
GROUP BY h."hub_id", h."hub_name"
HAVING SUM(CASE WHEN o."order_created_month" = 2 THEN 1 ELSE 0 END) > 0
   AND SUM(CASE WHEN o."order_created_month" = 3 THEN 1 ELSE 0 END) >
       SUM(CASE WHEN o."order_created_month" = 2 THEN 1 ELSE 0 END) * 1.20;