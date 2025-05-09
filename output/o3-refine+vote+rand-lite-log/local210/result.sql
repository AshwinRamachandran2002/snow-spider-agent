WITH finished_orders AS (
    SELECT
        s.hub_id,
        o.order_created_month AS month
    FROM orders AS o
    JOIN stores AS s   ON s.store_id = o.store_id
    WHERE o.order_status = 'FINISHED'
      AND o.order_created_month IN (2, 3)          -- February or March
),
monthly_totals AS (
    SELECT
        hub_id,
        month,
        COUNT(*) AS total_finished
    FROM finished_orders
    GROUP BY hub_id, month
),
pivot_totals AS (
    SELECT
        hub_id,
        SUM(CASE WHEN month = 2 THEN total_finished ELSE 0 END) AS feb_finished,
        SUM(CASE WHEN month = 3 THEN total_finished ELSE 0 END) AS mar_finished
    FROM monthly_totals
    GROUP BY hub_id
)
SELECT
    h.hub_id,
    h.hub_name
FROM pivot_totals AS p
JOIN hubs AS h ON h.hub_id = p.hub_id
WHERE p.feb_finished > 0                          -- need a February base to compare
  AND p.mar_finished > p.feb_finished * 1.20;     -- >20 % increase