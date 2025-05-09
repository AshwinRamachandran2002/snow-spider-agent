WITH annual_sales AS (
    SELECT
        "salespersonid",
        substr("orderdate", 1, 4) AS year,
        SUM("totaldue") AS total_sales
    FROM "salesorderheader"
    WHERE "salespersonid" IS NOT NULL
    GROUP BY "salespersonid", substr("orderdate", 1, 4)
),
annual_quota AS (
    SELECT
        "BusinessEntityID"      AS salespersonid,
        substr("QuotaDate", 1, 4) AS year,
        SUM("SalesQuota")       AS annual_quota
    FROM "SalesPersonQuotaHistory"
    GROUP BY "BusinessEntityID", substr("QuotaDate", 1, 4)
)
SELECT
    s.salespersonid,
    s.year,
    s.total_sales,
    q.annual_quota,
    (s.total_sales - q.annual_quota) AS sales_minus_quota
FROM annual_sales s
JOIN annual_quota q
  ON s.salespersonid = q.salespersonid
 AND s.year          = q.year
ORDER BY
    s.salespersonid,
    s.year;