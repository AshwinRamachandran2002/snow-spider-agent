WITH monthly_totals AS (
    SELECT
        h."hub_id",
        h."hub_name",
        SUM(CASE WHEN o."order_created_month" = 2 THEN 1 ELSE 0 END) AS feb_finished,
        SUM(CASE WHEN o."order_created_month" = 3 THEN 1 ELSE 0 END) AS mar_finished
    FROM "orders"  o
    JOIN "stores"  s ON s."store_id" = o."store_id"
    JOIN "hubs"    h ON h."hub_id"   = s."hub_id"
    WHERE o."order_status"       = 'FINISHED'
      AND o."order_created_year" = 2021
      AND o."order_created_month" IN (2, 3)
    GROUP BY h."hub_id", h."hub_name"
)
SELECT
    "hub_id",
    "hub_name",
    feb_finished,
    mar_finished,
    ROUND( (mar_finished - feb_finished) * 100.0 / feb_finished, 1) AS pct_change
FROM   monthly_totals
WHERE  feb_finished > 0                                    -- avoid division by zero
  AND  (mar_finished - feb_finished) * 1.0 / feb_finished > 0.20 -- > 20% growth
ORDER BY pct_change DESC;