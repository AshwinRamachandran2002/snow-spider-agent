SELECT "employeeid" AS "EmployeeID",
       SUM(CASE WHEN "shippeddate" >= "requireddate" THEN 1 ELSE 0 END) AS "Number_of_Late_Orders",
       ROUND((SUM(CASE WHEN "shippeddate" >= "requireddate" THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 4) AS "Late_Order_Percentage"
FROM "orders"
GROUP BY "employeeid"
HAVING COUNT(*) > 50
ORDER BY "Late_Order_Percentage" DESC
LIMIT 3;