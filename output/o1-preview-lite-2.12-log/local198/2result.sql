WITH TotalSales AS (
  SELECT c."Country", SUM(i."Total") AS "TotalSales"
  FROM "customers" c
  JOIN "invoices" i ON c."CustomerId" = i."CustomerId"
  GROUP BY c."Country"
  HAVING COUNT(c."CustomerId") > 4
)
SELECT ROUND(AVG("TotalSales"), 4) AS "Median_Total_Sales"
FROM (
  SELECT "TotalSales"
  FROM TotalSales
  ORDER BY "TotalSales"
  LIMIT 2
  OFFSET (SELECT (COUNT(*) / 2) - 1 FROM TotalSales)
);