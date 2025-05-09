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