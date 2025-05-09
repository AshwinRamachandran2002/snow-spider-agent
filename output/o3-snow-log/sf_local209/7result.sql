WITH store_stats AS (
    SELECT
        o."store_id",
        s."store_name",
        COUNT(*)                                                       AS "total_orders",
        SUM(CASE WHEN d."delivery_status" = 'DELIVERED' THEN 1 END)    AS "delivered_orders"
    FROM DELIVERY_CENTER.DELIVERY_CENTER.ORDERS      o
    JOIN DELIVERY_CENTER.DELIVERY_CENTER.STORES      s
          ON o."store_id" = s."store_id"
    LEFT JOIN DELIVERY_CENTER.DELIVERY_CENTER.DELIVERIES d
          ON o."delivery_order_id" = d."delivery_order_id"
    GROUP BY o."store_id", s."store_name"
)

SELECT
    "store_id",
    "store_name",
    "total_orders",
    ROUND( "delivered_orders" / NULLIF("total_orders", 0), 4) AS "delivered_to_total_ratio"
FROM store_stats
ORDER BY "total_orders" DESC NULLS LAST
LIMIT 1;