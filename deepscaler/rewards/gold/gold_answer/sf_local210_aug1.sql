-- Task: Find the number of finished orders for each hub in March.
SELECT
    h."hub_name" AS "hub_name",
    COUNT(*) AS "orders_march"
FROM 
    DELIVERY_CENTER.DELIVERY_CENTER.ORDERS AS o
LEFT JOIN
    DELIVERY_CENTER.DELIVERY_CENTER.STORES AS s ON o."store_id" = s."store_id"
LEFT JOIN 
    DELIVERY_CENTER.DELIVERY_CENTER.HUBS AS h ON s."hub_id" = h."hub_id"
WHERE 
    o."order_created_month" = 3 AND o."order_status" = 'FINISHED'
GROUP BY
    h."hub_name";