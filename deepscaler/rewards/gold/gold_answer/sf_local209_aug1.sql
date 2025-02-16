-- Task: In the dataset of orders joined with store information, which store has the highest total number of orders?
SELECT
    s."store_name",
    COUNT(o."order_id") AS total_orders
FROM
    DELIVERY_CENTER.DELIVERY_CENTER.ORDERS o
LEFT JOIN
    DELIVERY_CENTER.DELIVERY_CENTER.STORES s ON o."store_id" = s."store_id"
GROUP BY
    s."store_name"
ORDER BY
    total_orders DESC
LIMIT 1;