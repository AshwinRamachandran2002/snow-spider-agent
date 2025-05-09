SELECT 
    dl.driver_id,
    ROUND(
        CAST(COUNT(dl.delivery_id) AS FLOAT) /
        COUNT(
            DISTINCT printf('%04d-%02d-%02d',
                            o.order_created_year,
                            o.order_created_month,
                            o.order_created_day)
        ), 
        4
    ) AS avg_daily_deliveries
FROM deliveries AS dl
JOIN orders AS o
      ON o.order_id = dl.delivery_order_id
WHERE dl.delivery_status = 'DELIVERED'
GROUP BY dl.driver_id
HAVING COUNT(
         DISTINCT printf('%04d-%02d-%02d',
                         o.order_created_year,
                         o.order_created_month,
                         o.order_created_day)
       ) > 0
ORDER BY avg_daily_deliveries DESC,
         dl.driver_id
LIMIT 5;