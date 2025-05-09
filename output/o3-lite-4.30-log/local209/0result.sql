WITH total_per_store AS (
    SELECT "store_id",
           COUNT(DISTINCT "order_id") AS total_orders
    FROM "orders"
    GROUP BY "store_id"
),
top_store AS (
    SELECT "store_id",
           total_orders
    FROM total_per_store
    ORDER BY total_orders DESC, "store_id"
    LIMIT 1
),
delivered_per_store AS (
    SELECT o."store_id",
           COUNT(DISTINCT o."order_id") AS delivered_orders
    FROM "orders" o
    JOIN "deliveries" d
      ON d."delivery_order_id" = o."delivery_order_id"
     AND d."delivery_status" = 'DELIVERED'
    GROUP BY o."store_id"
),
final AS (
    SELECT t."store_id",
           ROUND(
               CAST(COALESCE(d.delivered_orders, 0) AS FLOAT) / t.total_orders,
               4
           ) AS delivered_to_total_ratio
    FROM top_store t
    LEFT JOIN delivered_per_store d
      ON d."store_id" = t."store_id"
)
SELECT *
FROM final;