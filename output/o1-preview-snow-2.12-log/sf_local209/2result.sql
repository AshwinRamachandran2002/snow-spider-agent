SELECT s."store_id", s."store_name",
       COUNT(o."order_id") AS total_orders,
       ROUND(SUM(CASE WHEN d."delivery_status" = 'DELIVERED' THEN 1 ELSE 0 END)::FLOAT / COUNT(o."order_id"), 4) AS delivered_ratio
FROM DELIVERY_CENTER.DELIVERY_CENTER.ORDERS o
JOIN DELIVERY_CENTER.DELIVERY_CENTER.STORES s ON o."store_id" = s."store_id"
LEFT JOIN DELIVERY_CENTER.DELIVERY_CENTER.DELIVERIES d ON o."delivery_order_id" = d."delivery_order_id"
WHERE o."store_id" = (
    SELECT o2."store_id"
    FROM DELIVERY_CENTER.DELIVERY_CENTER.ORDERS o2
    GROUP BY o2."store_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
)
GROUP BY s."store_id", s."store_name";