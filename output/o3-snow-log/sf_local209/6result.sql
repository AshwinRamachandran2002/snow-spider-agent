WITH store_agg AS (
    SELECT
        o."store_id",
        COUNT(*)                                                         AS "total_orders",
        SUM(CASE WHEN d."delivery_status" = 'DELIVERED' THEN 1 ELSE 0 END) AS "delivered_orders"
    FROM DELIVERY_CENTER.DELIVERY_CENTER."ORDERS"      o
    LEFT JOIN DELIVERY_CENTER.DELIVERY_CENTER."DELIVERIES" d
           ON o."delivery_order_id" = d."delivery_order_id"
    GROUP BY o."store_id"
), ranked AS (
    SELECT
        a.*,
        ROW_NUMBER() OVER (ORDER BY a."total_orders" DESC NULLS LAST) AS rn
    FROM store_agg a
)
SELECT
    s."store_name",
    r."total_orders",
    r."delivered_orders",
    r."delivered_orders" / r."total_orders"::FLOAT AS "delivered_ratio"
FROM ranked r
JOIN DELIVERY_CENTER.DELIVERY_CENTER."STORES" s
  ON r."store_id" = s."store_id"
WHERE r.rn = 1;