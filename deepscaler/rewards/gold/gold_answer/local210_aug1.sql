-- Task: List the number of finished orders in February for each hub
SELECT
    h.hub_name AS hub_name,
    COUNT(*) AS orders_february
FROM 
    orders o 
LEFT JOIN
    stores s ON o.store_id = s.store_id 
LEFT JOIN 
    hubs h ON s.hub_id = h.hub_id 
WHERE 
    o.order_created_month = 2 
    AND o.order_status = 'FINISHED'
GROUP BY
    h.hub_name;