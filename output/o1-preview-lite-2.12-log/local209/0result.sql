SELECT s."store_name",
       COUNT(o."order_id") AS "Total_Orders",
       COUNT(d."delivery_order_id") AS "Delivered_Orders",
       ROUND(COUNT(d."delivery_order_id") * 1.0 / COUNT(o."order_id"), 4) AS "Delivery_Ratio"
FROM "orders" AS o
JOIN "stores" AS s ON o."store_id" = s."store_id"
LEFT JOIN (
    SELECT "delivery_order_id"
    FROM "deliveries"
    WHERE "delivery_status" = 'DELIVERED'
) AS d ON o."delivery_order_id" = d."delivery_order_id"
GROUP BY s."store_name"
ORDER BY "Total_Orders" DESC
LIMIT 1;