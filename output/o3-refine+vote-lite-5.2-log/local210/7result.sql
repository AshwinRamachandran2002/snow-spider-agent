WITH monthly_finished AS (
    SELECT
        s.hub_id,
        o.order_created_year,
        o.order_created_month AS month,
        COUNT(*) AS finished_orders
    FROM orders  o
    JOIN stores  s ON s.store_id = o.store_id
    WHERE o.order_status = 'FINISHED'
      AND o.order_created_month IN (2, 3)          -- February and March
    GROUP BY s.hub_id, o.order_created_year, o.order_created_month
),
pivot AS (
    SELECT
        hub_id,
        order_created_year,
        SUM(CASE WHEN month = 2 THEN finished_orders END) AS feb_orders,
        SUM(CASE WHEN month = 3 THEN finished_orders END) AS mar_orders
    FROM monthly_finished
    GROUP BY hub_id, order_created_year
)
SELECT
    h.hub_id,
    h.hub_name
FROM pivot p
JOIN hubs h ON h.hub_id = p.hub_id
WHERE p.feb_orders IS NOT NULL
  AND p.mar_orders IS NOT NULL
  AND p.mar_orders > p.feb_orders * 1.2;