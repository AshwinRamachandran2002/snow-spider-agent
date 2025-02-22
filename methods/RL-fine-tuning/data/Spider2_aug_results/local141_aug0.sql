-- Task: Calculate each salesperson's total sales and total sales quota for each year by summing 'TotalDue' from 'salesorderheader' and 'SalesQuota' from 'SalesPersonQuotaHistory', respectively. Use the year extracted from 'OrderDate' and 'QuotaDate' for grouping. Exclude entries with null or empty 'SalesPersonID' in 'salesorderheader'. Then, compute the difference between the total sales and the total quota for each salesperson and year. Present the results with SalesPersonID, Year, TotalSales, SalesQuota, and the Difference (TotalSales minus SalesQuota), rounded to four decimal places, and sort the records by SalesPersonID and Year.
SELECT ts."SalesPersonID",
       ts."Year",
       ROUND(ts."TotalSales", 4) AS "TotalSales",
       ROUND(tq."TotalQuota", 4) AS "SalesQuota",
       ROUND(ts."TotalSales" - tq."TotalQuota", 4) AS "Difference"
FROM (
  SELECT "SalesPersonID",
         strftime('%Y', "OrderDate") AS "Year",
         SUM("TotalDue") AS "TotalSales"
  FROM "salesorderheader"
  WHERE "SalesPersonID" IS NOT NULL
    AND "SalesPersonID" != ''
  GROUP BY "SalesPersonID", "Year"
) ts
JOIN (
  SELECT "BusinessEntityID" AS "SalesPersonID",
         strftime('%Y', "QuotaDate") AS "Year",
         SUM("SalesQuota") AS "TotalQuota"
  FROM "SalesPersonQuotaHistory"
  GROUP BY "BusinessEntityID", "Year"
) tq
  ON ts."SalesPersonID" = tq."SalesPersonID"
 AND ts."Year" = tq."Year"
ORDER BY ts."SalesPersonID", ts."Year";