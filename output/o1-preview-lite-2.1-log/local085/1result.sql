SELECT "employeeid" AS "EmployeeID",
       SUM(CASE WHEN "shippeddate" > "requireddate" THEN 1 ELSE 0 END) AS "Number_of_Late_Orders",
       ROUND((SUM(CASE WHEN "shippeddate" > "requireddate" THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 4) AS "Percentage_of_Late_Orders"
FROM "orders"
GROUP BY "employeeid"
HAVING COUNT(*) > 50
ORDER BY "Percentage_of_Late_Orders" DESC
LIMIT 3;