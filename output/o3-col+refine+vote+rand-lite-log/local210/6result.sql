WITH feb AS (
    SELECT  h."hub_id",
            h."hub_name",
            COUNT(DISTINCT o."order_id") AS "feb_finished_orders"
    FROM   "orders" o
    JOIN   "stores" s ON o."store_id" = s."store_id"
    JOIN   "hubs"   h ON s."hub_id"  = h."hub_id"
    WHERE  o."order_created_month" = 2
      AND  o."order_status"        = 'FINISHED'
    GROUP BY h."hub_id", h."hub_name"
),
mar AS (
    SELECT  h."hub_id",
            h."hub_name",
            COUNT(DISTINCT o."order_id") AS "mar_finished_orders"
    FROM   "orders" o
    JOIN   "stores" s ON o."store_id" = s."store_id"
    JOIN   "hubs"   h ON s."hub_id"  = h."hub_id"
    WHERE  o."order_created_month" = 3
      AND  o."order_status"        = 'FINISHED'
    GROUP BY h."hub_id", h."hub_name"
),
base AS (
    SELECT  f."hub_id",
            f."hub_name",
            f."feb_finished_orders",
            m."mar_finished_orders",
            (m."mar_finished_orders" - f."feb_finished_orders") * 100.0
            / f."feb_finished_orders"      AS "perc_increase"
    FROM    feb f
    JOIN    mar m  ON f."hub_id" = m."hub_id"
)
SELECT  "hub_id",
        "hub_name",
        ROUND("perc_increase", 2) AS "perc_increase"
FROM    base
WHERE   "perc_increase" > 20          -- more than 20% growth
ORDER BY "perc_increase" DESC;