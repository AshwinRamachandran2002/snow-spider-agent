WITH store_totals AS (
    SELECT o."store_id",
           COUNT(*) AS total_orders
    FROM   "orders" o
    GROUP  BY o."store_id"
),
top_store AS (                  -- store with the most orders
    SELECT *
    FROM   store_totals
    ORDER  BY total_orders DESC
    LIMIT  1
),
delivered_totals AS (           -- delivered orders for every store
    SELECT o."store_id",
           COUNT(*) AS delivered_orders
    FROM   "orders"     o
    JOIN   "deliveries" d
           ON d."delivery_order_id" = o."delivery_order_id"
    WHERE  d."delivery_status" = 'DELIVERED'
    GROUP  BY o."store_id"
)
SELECT  s."store_id",
        s."store_name",
        t.total_orders,
        d.delivered_orders,
        ROUND(CAST(d.delivered_orders AS REAL) / t.total_orders, 4) AS delivered_ratio
FROM    top_store        t
LEFT    JOIN delivered_totals d ON d."store_id" = t."store_id"
JOIN    "stores"         s ON s."store_id" = t."store_id";