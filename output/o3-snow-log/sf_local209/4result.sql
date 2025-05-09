/* Find the store with the most orders and its delivered-order ratio */
WITH per_store AS (
    SELECT
        o."store_id",
        COUNT(*)                                                                      AS "total_orders",
        COUNT(CASE WHEN d."delivery_status" = 'DELIVERED' THEN 1 END)                 AS "delivered_orders"
    FROM DELIVERY_CENTER.DELIVERY_CENTER.ORDERS     o
    LEFT JOIN DELIVERY_CENTER.DELIVERY_CENTER.DELIVERIES d
           ON o."delivery_order_id" = d."delivery_order_id"
    GROUP BY o."store_id"
),
top_store AS (
    SELECT *
    FROM per_store
    ORDER BY "total_orders" DESC NULLS LAST
    LIMIT 1
)
SELECT
    s."store_name",
    t."total_orders",
    t."delivered_orders",
    ROUND(t."delivered_orders" / t."total_orders"::FLOAT, 4) AS "delivered_ratio"
FROM top_store t
JOIN DELIVERY_CENTER.DELIVERY_CENTER.STORES s
      ON t."store_id" = s."store_id";