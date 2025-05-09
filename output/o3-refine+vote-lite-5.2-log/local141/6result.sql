WITH annual_sales AS (
    -- total sales (before tax and freight) per salesperson and year
    SELECT
        "salesorderheader"."salespersonid"       AS BusinessEntityID,
        CAST(strftime('%Y', "salesorderheader"."orderdate") AS INTEGER) AS SalesYear,
        SUM("salesorderheader"."subtotal")       AS TotalSales
    FROM "salesorderheader"
    WHERE "salesorderheader"."salespersonid" IS NOT NULL
    GROUP BY BusinessEntityID, SalesYear
),
annual_quota AS (
    -- total quota assigned to each salesperson per year
    SELECT
        "SalesPersonQuotaHistory"."BusinessEntityID",
        CAST(strftime('%Y', "SalesPersonQuotaHistory"."QuotaDate") AS INTEGER) AS SalesYear,
        SUM("SalesPersonQuotaHistory"."SalesQuota")                AS AnnualQuota
    FROM "SalesPersonQuotaHistory"
    GROUP BY BusinessEntityID, SalesYear
),
all_years AS (
    -- union of every (salesperson, year) that appears in either table
    SELECT BusinessEntityID, SalesYear FROM annual_sales
    UNION
    SELECT BusinessEntityID, SalesYear FROM annual_quota
)
SELECT
    ay.BusinessEntityID,
    ay.SalesYear                                  AS Year,
    COALESCE(asl.TotalSales, 0)                   AS TotalSales,
    COALESCE(aq.AnnualQuota, 0)                   AS AnnualQuota,
    COALESCE(asl.TotalSales, 0) - 
    COALESCE(aq.AnnualQuota, 0)                   AS Difference
FROM all_years   ay
LEFT JOIN annual_sales  asl
       ON asl.BusinessEntityID = ay.BusinessEntityID
      AND asl.SalesYear       = ay.SalesYear
LEFT JOIN annual_quota  aq
       ON aq.BusinessEntityID = ay.BusinessEntityID
      AND aq.SalesYear       = ay.SalesYear
ORDER BY ay.BusinessEntityID, ay.SalesYear;