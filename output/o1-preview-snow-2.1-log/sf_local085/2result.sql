SELECT "employeeid", 
       SUM(CASE WHEN "shippeddate" > "requireddate" THEN 1 ELSE 0 END) AS "late_orders", 
       COUNT("orderid") AS "total_orders", 
       ROUND(SUM(CASE WHEN "shippeddate" > "requireddate" THEN 1 ELSE 0 END) * 100.0 / COUNT("orderid"), 4) AS "late_percentage"
FROM "NORTHWIND"."NORTHWIND"."ORDERS"
GROUP BY "employeeid"
HAVING COUNT("orderid") > 50
ORDER BY "late_percentage" DESC NULLS LAST
LIMIT 3;