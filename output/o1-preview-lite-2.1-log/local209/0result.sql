SELECT
  "store_id",
  ROUND(SUM(CASE WHEN "order_status" = 'FINISHED' THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 4) AS "ratio_completed_orders"
FROM "orders"
GROUP BY "store_id"
ORDER BY COUNT(*) DESC
LIMIT 1;