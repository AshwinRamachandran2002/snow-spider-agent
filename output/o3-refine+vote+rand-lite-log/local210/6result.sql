WITH monthly_finished AS (
    /* 1. Finished orders per hub, per year, only for February and March */
    SELECT
        h.hub_id,
        h.hub_name,
        o.order_created_year  AS yr,
        o.order_created_month AS mn,
        COUNT(*)              AS finished_qty
    FROM orders  o
    JOIN stores  s ON s.store_id = o.store_id
    JOIN hubs    h ON h.hub_id   = s.hub_id
    WHERE o.order_status = 'FINISHED'
      AND o.order_created_month IN (2, 3)          -- February & March
    GROUP BY h.hub_id, h.hub_name, o.order_created_year, o.order_created_month
),
pivot AS (
    /* 2. Put February and March side‑by‑side */
    SELECT
        hub_id,
        hub_name,
        yr,
        SUM(CASE WHEN mn = 2 THEN finished_qty END) AS feb_orders,
        SUM(CASE WHEN mn = 3 THEN finished_qty END) AS mar_orders
    FROM monthly_finished
    GROUP BY hub_id, hub_name, yr
)
SELECT
    hub_id,
    hub_name,
    yr                    AS year,
    feb_orders,
    mar_orders,
    ROUND( (mar_orders - feb_orders) * 100.0 / feb_orders , 2) AS percent_increase
FROM pivot
WHERE feb_orders > 0                               -- avoid division by zero
  AND mar_orders > feb_orders * 1.2;               -- > 20% growth