WITH monthly_finished AS (
    SELECT
        h.hub_id,
        h.hub_name,
        o.order_created_year  AS yr,
        o.order_created_month AS mo,
        COUNT(*)              AS finished_qty
    FROM orders  o
    JOIN stores  s ON o.store_id = s.store_id
    JOIN hubs    h ON s.hub_id  = h.hub_id
    WHERE o.order_status = 'FINISHED'
      AND o.order_created_month IN (2, 3)        -- February and March
    GROUP BY h.hub_id, h.hub_name, o.order_created_year, o.order_created_month
),
feb_mar_pivot AS (
    SELECT
        hub_id,
        hub_name,
        yr,
        SUM(CASE WHEN mo = 2 THEN finished_qty END) AS feb_finished,
        SUM(CASE WHEN mo = 3 THEN finished_qty END) AS mar_finished
    FROM monthly_finished
    GROUP BY hub_id, hub_name, yr
)
SELECT
    hub_id,
    hub_name,
    yr,
    feb_finished,
    mar_finished
FROM feb_mar_pivot
WHERE feb_finished IS NOT NULL          -- a February baseline
  AND mar_finished IS NOT NULL          -- must also have March data
  AND mar_finished > 1.20 * feb_finished -- >20 % increase
ORDER BY hub_id, yr;