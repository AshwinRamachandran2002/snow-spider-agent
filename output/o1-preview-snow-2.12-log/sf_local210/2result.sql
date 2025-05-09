SELECT
    hub_orders."hub_id",
    hub_orders."hub_name"
FROM (
    SELECT
        hubs."hub_id",
        hubs."hub_name",
        SUM(CASE WHEN orders."order_created_month" = 2 THEN 1 ELSE 0 END) AS "feb_finished_orders",
        SUM(CASE WHEN orders."order_created_month" = 3 THEN 1 ELSE 0 END) AS "mar_finished_orders"
    FROM
        "DELIVERY_CENTER"."DELIVERY_CENTER"."ORDERS" AS orders
    JOIN
        "DELIVERY_CENTER"."DELIVERY_CENTER"."STORES" AS stores
        ON orders."store_id" = stores."store_id"
    JOIN
        "DELIVERY_CENTER"."DELIVERY_CENTER"."HUBS" AS hubs
        ON stores."hub_id" = hubs."hub_id"
    WHERE
        orders."order_status" = 'FINISHED'
        AND orders."order_created_month" IN (2, 3)
        AND orders."order_created_year" = 2021
    GROUP BY
        hubs."hub_id",
        hubs."hub_name"
) AS hub_orders
WHERE
    hub_orders."feb_finished_orders" > 0
    AND ROUND(((hub_orders."mar_finished_orders" - hub_orders."feb_finished_orders") * 1.0 / hub_orders."feb_finished_orders") * 100, 4) > 20;