WITH finished_orders AS (
    SELECT
        s.hub_id,
        o.order_created_year  AS yr,
        o.order_created_month AS mn
    FROM orders  o
    JOIN stores  s ON s.store_id = o.store_id
    WHERE o.order_status = 'FINISHED'          -- only finished orders
),
month_totals AS (
    SELECT
        hub_id,
        yr,
        SUM(CASE WHEN mn = 2 THEN 1 ELSE 0 END) AS feb_orders,
        SUM(CASE WHEN mn = 3 THEN 1 ELSE 0 END) AS mar_orders
    FROM finished_orders
    GROUP BY hub_id, yr
),
increased_hubs AS (
    SELECT
        hub_id
    FROM month_totals
    WHERE feb_orders > 0                       -- avoid division by zero
      AND mar_orders > feb_orders * 1.2        -- > 20 % increase
)
SELECT DISTINCT
       h.hub_id,
       h.hub_name
FROM increased_hubs ih
JOIN hubs h ON h.hub_id = ih.hub_id
ORDER BY h.hub_id;