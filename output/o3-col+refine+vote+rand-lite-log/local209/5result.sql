WITH store_totals AS (
    SELECT 
        o."store_id",
        COUNT(*) AS total_orders
    FROM "orders" AS o
    GROUP BY o."store_id"
),
top_store AS (
    SELECT 
        st."store_id",
        st.total_orders
    FROM store_totals AS st
    ORDER BY st.total_orders DESC
    LIMIT 1
),
delivered_counts AS (
    SELECT 
        o."store_id",
        COUNT(*) AS delivered_orders
    FROM "orders" AS o
    JOIN "deliveries" AS d
      ON o."delivery_order_id" = d."delivery_order_id"
    WHERE d."delivery_status" = 'DELIVERED'
    GROUP BY o."store_id"
)
SELECT 
    ts."store_id",
    s."store_name",
    ts.total_orders,
    COALESCE(dc.delivered_orders, 0) AS delivered_orders,
    ROUND(COALESCE(dc.delivered_orders, 0) * 1.0 / ts.total_orders, 4) AS delivered_ratio
FROM top_store AS ts
LEFT JOIN delivered_counts AS dc
  ON ts."store_id" = dc."store_id"
JOIN "stores" AS s
  ON ts."store_id" = s."store_id";