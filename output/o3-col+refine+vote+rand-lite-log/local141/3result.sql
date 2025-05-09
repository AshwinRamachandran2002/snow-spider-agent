WITH sales_totals AS (
    SELECT
        salespersonid,
        strftime('%Y', orderdate) AS year,
        SUM(subtotal)            AS total_sales
    FROM salesorderheader
    WHERE salespersonid IS NOT NULL
    GROUP BY salespersonid, year
),
quota_totals AS (
    SELECT
        BusinessEntityID        AS salespersonid,
        strftime('%Y', QuotaDate) AS year,
        SUM(SalesQuota)         AS annual_quota
    FROM SalesPersonQuotaHistory
    GROUP BY salespersonid, year
)
SELECT
    s.salespersonid                 AS salesperson_id,
    s.year,
    ROUND(s.total_sales, 4)         AS total_sales,
    ROUND(q.annual_quota, 4)        AS annual_quota,
    ROUND(s.total_sales - q.annual_quota, 4) AS sales_minus_quota
FROM sales_totals s
JOIN quota_totals q
  ON s.salespersonid = q.salespersonid
 AND s.year          = q.year
ORDER BY s.salespersonid, s.year;