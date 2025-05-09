WITH order_counts AS (
    SELECT
        s."hub_id",
        h."hub_name",
        SUM(CASE WHEN o."order_created_month" = 2 THEN 1 ELSE 0 END) AS feb_finished_orders,
        SUM(CASE WHEN o."order_created_month" = 3 THEN 1 ELSE 0 END) AS mar_finished_orders
    FROM 
        "DELIVERY_CENTER"."DELIVERY_CENTER"."ORDERS" o
    JOIN 
        "DELIVERY_CENTER"."DELIVERY_CENTER"."STORES" s ON o."store_id" = s."store_id"
    JOIN 
        "DELIVERY_CENTER"."DELIVERY_CENTER"."HUBS" h ON s."hub_id" = h."hub_id"
    WHERE 
        o."order_status" = 'FINISHED' AND 
        o."order_created_month" IN (2, 3)
    GROUP BY
        s."hub_id",
        h."hub_name"
)
SELECT
    "hub_id",
    "hub_name"
FROM
    order_counts
WHERE
    feb_finished_orders > 0 AND
    ((mar_finished_orders - feb_finished_orders) / feb_finished_orders::float) * 100 > 20;