WITH
-- annual sales for every salesperson
sales_per_year AS (
    SELECT
        "salespersonid"                 AS BusinessEntityID,
        strftime('%Y', "orderdate")     AS SalesYear,
        SUM("totaldue")                 AS TotalSales
    FROM "salesorderheader"
    WHERE "salespersonid" IS NOT NULL
    GROUP BY "salespersonid", SalesYear
),

-- annual quota for every salesperson (sum of monthly quotas)
quota_per_year AS (
    SELECT
        "BusinessEntityID",
        strftime('%Y', "QuotaDate")     AS QuotaYear,
        SUM("SalesQuota")               AS AnnualQuota
    FROM "SalesPersonQuotaHistory"
    GROUP BY "BusinessEntityID", QuotaYear
),

-- collect every (salesperson, year) pair that appears in either list
all_pairs AS (
    SELECT BusinessEntityID, SalesYear AS Yr FROM sales_per_year
    UNION
    SELECT BusinessEntityID, QuotaYear       FROM quota_per_year
)

SELECT
    ap.BusinessEntityID,
    ap.Yr                                    AS Year,
    COALESCE(spy.TotalSales, 0)              AS TotalSales,
    COALESCE(qpy.AnnualQuota, 0)             AS AnnualQuota,
    ROUND(
        COALESCE(spy.TotalSales, 0) -
        COALESCE(qpy.AnnualQuota, 0), 4
    )                                        AS Difference
FROM          all_pairs          ap
LEFT JOIN     sales_per_year     spy
       ON ap.BusinessEntityID = spy.BusinessEntityID
      AND ap.Yr              = spy.SalesYear
LEFT JOIN     quota_per_year     qpy
       ON ap.BusinessEntityID = qpy.BusinessEntityID
      AND ap.Yr              = qpy.QuotaYear
ORDER BY
    ap.BusinessEntityID,
    ap.Yr;