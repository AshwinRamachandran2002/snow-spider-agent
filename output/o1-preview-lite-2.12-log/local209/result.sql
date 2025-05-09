SELECT s."store_name" AS Store_Name,
       COUNT(o."order_id") AS Total_Orders,
       SUM(CASE WHEN d."delivery_status" = 'DELIVERED' THEN 1 ELSE 0 END) AS Delivered_Orders,
       ROUND(CAST(SUM(CASE WHEN d."delivery_status" = 'DELIVERED' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(o."order_id"), 4) AS Delivery_Ratio
FROM "orders" o
JOIN "stores" s ON o."store_id" = s."store_id"
LEFT JOIN "deliveries" d ON o."delivery_order_id" = d."delivery_order_id"
GROUP BY s."store_name"
ORDER BY Total_Orders DESC
LIMIT 1;