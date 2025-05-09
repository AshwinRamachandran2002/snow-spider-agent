SELECT 
    COALESCE(s."SalesPersonID", q."SalesPersonID") AS "SalesPersonID", 
    COALESCE(s."Year", q."Year") AS "Year", 
    ROUND(COALESCE(s."TotalSales", 0), 4) AS "TotalSales", 
    ROUND(COALESCE(q."SalesQuota", 0), 4) AS "SalesQuota", 
    ROUND(COALESCE(s."TotalSales", 0) - COALESCE(q."SalesQuota", 0), 4) AS "Difference"
FROM (
    SELECT 
        CAST("salespersonid" AS NUMBER(38,0)) AS "SalesPersonID", 
        DATE_PART(year, TO_TIMESTAMP_NTZ("orderdate")) AS "Year", 
        SUM("totaldue") AS "TotalSales"
    FROM 
        "ADVENTUREWORKS"."ADVENTUREWORKS"."SALESORDERHEADER"
    WHERE "salespersonid" IS NOT NULL AND "salespersonid" != ''
    GROUP BY CAST("salespersonid" AS NUMBER(38,0)), DATE_PART(year, TO_TIMESTAMP_NTZ("orderdate"))
) s
FULL OUTER JOIN (
    SELECT 
        "BusinessEntityID" AS "SalesPersonID", 
        DATE_PART(year, TO_TIMESTAMP_NTZ("QuotaDate")) AS "Year", 
        SUM("SalesQuota") AS "SalesQuota"
    FROM 
        "ADVENTUREWORKS"."ADVENTUREWORKS"."SALESPERSONQUOTAHISTORY"
    GROUP BY "BusinessEntityID", DATE_PART(year, TO_TIMESTAMP_NTZ("QuotaDate"))
) q
ON s."SalesPersonID" = q."SalesPersonID" AND s."Year" = q."Year"
ORDER BY "SalesPersonID", "Year";