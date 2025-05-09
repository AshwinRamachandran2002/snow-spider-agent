SELECT
    soh."salespersonid" AS "SalesPersonID",
    strftime('%Y', soh."orderdate") AS "Year",
    ROUND(SUM(soh."totaldue"), 4) AS "TotalSales",
    ROUND(SUM(spqh."SalesQuota"), 4) AS "SalesQuota",
    ROUND(SUM(soh."totaldue") - SUM(spqh."SalesQuota"), 4) AS "Difference"
FROM "salesorderheader" AS soh
INNER JOIN "SalesPersonQuotaHistory" AS spqh
    ON soh."salespersonid" = spqh."BusinessEntityID"
      AND strftime('%Y', soh."orderdate") = strftime('%Y', spqh."QuotaDate")
WHERE soh."salespersonid" IS NOT NULL AND soh."salespersonid" != ''
GROUP BY soh."salespersonid", "Year"
ORDER BY soh."salespersonid", "Year";