SELECT
    h."hub_id",
    h."hub_name",
    SUM(CASE WHEN o."order_created_month" = 2 THEN 1 ELSE 0 END) AS "feb_finished",
    SUM(CASE WHEN o."order_created_month" = 3 THEN 1 ELSE 0 END) AS "mar_finished",
    ROUND(
        CAST(SUM(CASE WHEN o."order_created_month" = 3 THEN 1 ELSE 0 END) AS FLOAT) /
        NULLIF(SUM(CASE WHEN o."order_created_month" = 2 THEN 1 ELSE 0 END), 0) - 1,
        4
    ) AS "pct_increase"
FROM "orders" AS o
JOIN "stores" AS s
  ON o."store_id" = s."store_id"
JOIN "hubs" AS h
  ON s."hub_id" = h."hub_id"
WHERE o."order_status" = 'FINISHED'
  AND o."order_created_month" IN (2, 3)
GROUP BY h."hub_id", h."hub_name"
HAVING
    SUM(CASE WHEN o."order_created_month" = 2 THEN 1 ELSE 0 END) > 0      -- need Feb baseline
    AND CAST(SUM(CASE WHEN o."order_created_month" = 3 THEN 1 ELSE 0 END) AS FLOAT) >
        1.2 * SUM(CASE WHEN o."order_created_month" = 2 THEN 1 ELSE 0 END) -- >20% growth
ORDER BY "pct_increase" DESC;