SELECT "employeeid" AS "EmployeeID",
       COUNT(CASE WHEN "shippeddate" > "requireddate" THEN 1 END) AS "Number_of_Late_Orders",
       ROUND(
           COUNT(CASE WHEN "shippeddate" > "requireddate" THEN 1 END) * 100.0 / COUNT(*), 4
       ) AS "Percentage_of_Late_Orders"
FROM "orders"
WHERE "shippeddate" IS NOT NULL
  AND "requireddate" IS NOT NULL
GROUP BY "employeeid"
HAVING COUNT(*) > 50
ORDER BY "Percentage_of_Late_Orders" DESC
LIMIT 3;