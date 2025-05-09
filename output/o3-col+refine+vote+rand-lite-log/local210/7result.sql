WITH feb AS (   -- finished orders per hub in February 2021
    SELECT h."hub_id",
           h."hub_name",
           COUNT(*) AS "feb_finished_orders"
    FROM "orders"  o
    JOIN "stores"  s ON o."store_id" = s."store_id"
    JOIN "hubs"    h ON s."hub_id"  = h."hub_id"
    WHERE o."order_status"       = 'FINISHED'
      AND o."order_created_month" = 2
      AND o."order_created_year"  = 2021
    GROUP BY h."hub_id", h."hub_name"
),
mar AS (        -- finished orders per hub in March 2021
    SELECT h."hub_id",
           h."hub_name",
           COUNT(*) AS "mar_finished_orders"
    FROM "orders"  o
    JOIN "stores"  s ON o."store_id" = s."store_id"
    JOIN "hubs"    h ON s."hub_id"  = h."hub_id"
    WHERE o."order_status"       = 'FINISHED'
      AND o."order_created_month" = 3
      AND o."order_created_year"  = 2021
    GROUP BY h."hub_id", h."hub_name"
)
SELECT f."hub_id",
       f."hub_name",
       f."feb_finished_orders",
       m."mar_finished_orders",
       ROUND( (m."mar_finished_orders" - f."feb_finished_orders") * 1.0
              / f."feb_finished_orders" * 100, 2) AS "percentage_increase"
FROM feb AS f
JOIN mar AS m ON f."hub_id" = m."hub_id"
WHERE (m."mar_finished_orders" - f."feb_finished_orders") * 1.0
      / f."feb_finished_orders" > 0.20          -- more than 20 % growth
ORDER BY "percentage_increase" DESC;