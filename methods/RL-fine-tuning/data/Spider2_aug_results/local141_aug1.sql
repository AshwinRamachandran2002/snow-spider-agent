-- Task: Calculate the total annual sales for each salesperson, organized by salesperson and year.
SELECT "SalesPersonID",
       strftime('%Y', "OrderDate") AS "Year",
       SUM("TotalDue") AS "TotalSales"
FROM "salesorderheader"
WHERE "SalesPersonID" IS NOT NULL
  AND "SalesPersonID" != ''
GROUP BY "SalesPersonID", "Year"
ORDER BY "SalesPersonID", "Year";