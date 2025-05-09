WITH hub_orders AS (
    SELECT
        h."hub_id",
        h."hub_name",
        SUM(CASE WHEN o."order_status" = 'FINISHED' AND o."order_created_year" = 2021 AND o."order_created_month" = 2 THEN 1 ELSE 0 END) AS feb_orders,
        SUM(CASE WHEN o."order_status" = 'FINISHED' AND o."order_created_year" = 2021 AND o."order_created_month" = 3 THEN 1 ELSE 0 END) AS mar_orders
    FROM
        DELIVERY_CENTER.DELIVERY_CENTER."ORDERS" o
    JOIN
        DELIVERY_CENTER.DELIVERY_CENTER."STORES" s ON o."store_id" = s."store_id"
    JOIN
        DELIVERY_CENTER.DELIVERY_CENTER."HUBS" h ON s."hub_id" = h."hub_id"
    GROUP BY
        h."hub_id",
        h."hub_name"
)
SELECT
    "hub_id",
    "hub_name"
FROM
    hub_orders
WHERE
    feb_orders > 0
    AND (mar_orders - feb_orders) / feb_orders > 0.20;