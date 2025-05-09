SELECT
    hub_orders."hub_id",
    hub_orders."hub_name"
FROM
    (
        SELECT
            s."hub_id",
            h."hub_name",
            SUM(CASE WHEN o."order_status" = 'FINISHED' AND o."order_created_month" = 2 AND o."order_created_year" = 2021 THEN 1 ELSE 0 END) AS "orders_feb",
            SUM(CASE WHEN o."order_status" = 'FINISHED' AND o."order_created_month" = 3 AND o."order_created_year" = 2021 THEN 1 ELSE 0 END) AS "orders_mar"
        FROM
            "orders" o
        JOIN
            "stores" s ON o."store_id" = s."store_id"
        JOIN
            "hubs" h ON s."hub_id" = h."hub_id"
        GROUP BY
            s."hub_id", h."hub_name"
    ) AS hub_orders
WHERE
    hub_orders."orders_feb" > 0 AND
    ROUND((hub_orders."orders_mar" - hub_orders."orders_feb") * 1.0 / hub_orders."orders_feb", 4) > 0.20
;