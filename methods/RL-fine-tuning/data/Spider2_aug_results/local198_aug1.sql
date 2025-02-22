-- Task: Calculate the total sales per country for countries where the number of customers is greater than 4.
SELECT c."Country", SUM(i."Total") AS "TotalSales"
FROM "invoices" i
JOIN "customers" c ON i."CustomerId" = c."CustomerId"
WHERE c."Country" IN (
  SELECT "Country"
  FROM "customers"
  GROUP BY "Country"
  HAVING COUNT("CustomerId") > 4
)
GROUP BY c."Country";