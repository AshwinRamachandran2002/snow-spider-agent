SELECT
    "employeeid" AS "EmployeeID",
    SUM(CASE WHEN "shippeddate" > "requireddate" THEN 1 ELSE 0 END) AS "Number_of_Late_Orders",
    ROUND((CAST(SUM(CASE WHEN "shippeddate" > "requireddate" THEN 1 ELSE 0 END) AS REAL) / COUNT("orderid")) * 100, 4) AS "Percentage_of_Late_Orders"
FROM
    "orders"
GROUP BY
    "employeeid"
HAVING
    COUNT("orderid") > 50
ORDER BY
    "Percentage_of_Late_Orders" DESC
LIMIT 3;