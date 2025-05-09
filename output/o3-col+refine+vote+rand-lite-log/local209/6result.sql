WITH total AS (
    SELECT o."store_id",
           COUNT(*) AS total_orders
    FROM   "orders" AS o
    GROUP  BY o."store_id"
),
delivered AS (
    SELECT o."store_id",
           COUNT(*) AS delivered_orders
    FROM   "orders"     AS o
    JOIN   "deliveries" AS d
           ON o."delivery_order_id" = d."delivery_order_id"
    WHERE  d."delivery_status" = 'DELIVERED'
    GROUP  BY o."store_id"
),
combined AS (
    SELECT t."store_id",
           t.total_orders,
           COALESCE(d.delivered_orders, 0) AS delivered_orders
    FROM   total      AS t
    LEFT JOIN delivered AS d
           ON t."store_id" = d."store_id"
)
SELECT   c."store_id",
         s."store_name",
         c.total_orders,
         ROUND(1.0 * c.delivered_orders / c.total_orders, 4) AS delivered_ratio
FROM     combined AS c
JOIN     "stores" AS s
         ON c."store_id" = s."store_id"
ORDER BY c.total_orders DESC
LIMIT 1;