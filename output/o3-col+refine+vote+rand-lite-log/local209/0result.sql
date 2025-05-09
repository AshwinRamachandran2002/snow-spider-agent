SELECT
       s."store_name",
       t."total_orders",
       t."delivered_orders",
       ROUND(CAST(t."delivered_orders" AS REAL) / t."total_orders", 4) AS "delivered_ratio"
FROM (
        SELECT
               o."store_id",
               COUNT(*)                                                     AS "total_orders",
               SUM(CASE WHEN d."delivery_status" = 'DELIVERED' THEN 1 ELSE 0 END) AS "delivered_orders"
        FROM   "orders" AS o
        LEFT JOIN "deliveries" AS d
               ON d."delivery_order_id" = o."delivery_order_id"
        GROUP  BY o."store_id"
        ORDER  BY COUNT(*) DESC
        LIMIT 1
     ) AS t
JOIN   "stores" AS s
       ON s."store_id" = t."store_id";