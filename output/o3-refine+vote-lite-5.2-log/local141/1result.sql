WITH
-- all (salesperson,year) pairs that appear in either sales or quota data
years AS (
    SELECT salespersonid AS BusinessEntityID,
           CAST(strftime('%Y', orderdate) AS INTEGER) AS Year
    FROM salesorderheader
    UNION
    SELECT BusinessEntityID,
           CAST(strftime('%Y', QuotaDate) AS INTEGER) AS Year
    FROM SalesPersonQuotaHistory
),
comb AS (              -- distinct list of salesperson/year to report on
    SELECT DISTINCT BusinessEntityID, Year FROM years
),
-- yearly total sales value (TotalDue) for each salesperson
sales AS (
    SELECT salespersonid AS BusinessEntityID,
           CAST(strftime('%Y', orderdate) AS INTEGER) AS Year,
           SUM(totaldue) AS total_sales
    FROM salesorderheader
    GROUP BY salespersonid, Year
),
-- yearly quota (sum of all quota rows for that year) for each salesperson
quota AS (
    SELECT BusinessEntityID,
           CAST(strftime('%Y', QuotaDate) AS INTEGER) AS Year,
           SUM(SalesQuota) AS total_quota
    FROM SalesPersonQuotaHistory
    GROUP BY BusinessEntityID, Year
)
SELECT
    c.BusinessEntityID,          -- salesperson
    c.Year,                      -- calendar year
    COALESCE(s.total_sales, 0)  AS total_sales,
    COALESCE(q.total_quota, 0)  AS total_quota,
    COALESCE(s.total_sales, 0) - COALESCE(q.total_quota, 0) AS difference
FROM comb AS c
LEFT JOIN sales AS s
       ON c.BusinessEntityID = s.BusinessEntityID
      AND c.Year            = s.Year
LEFT JOIN quota AS q
       ON c.BusinessEntityID = q.BusinessEntityID
      AND c.Year            = q.Year
ORDER BY c.BusinessEntityID, c.Year;