SELECT "employeeid",
       SUM(CASE WHEN TRY_TO_DATE("shippeddate", 'YYYY-MM-DD') > TRY_TO_DATE("requireddate", 'YYYY-MM-DD') THEN 1 ELSE 0 END) AS "late_orders",
       COUNT(*) AS "total_orders",
       ROUND(100.0 * SUM(CASE WHEN TRY_TO_DATE("shippeddate", 'YYYY-MM-DD') > TRY_TO_DATE("requireddate", 'YYYY-MM-DD') THEN 1 ELSE 0 END) / COUNT(*), 4) AS "late_percentage"
FROM "NORTHWIND"."NORTHWIND"."ORDERS"
WHERE "shippeddate" IS NOT NULL
GROUP BY "employeeid"
HAVING COUNT(*) > 50
ORDER BY "late_percentage" DESC NULLS LAST
LIMIT 3;