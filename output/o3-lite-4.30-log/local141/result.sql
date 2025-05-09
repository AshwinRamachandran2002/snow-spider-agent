WITH sales AS (
    SELECT
        salespersonid                 AS salesperson,
        strftime('%Y', orderdate)     AS year,
        SUM(totaldue)                 AS total_sales
    FROM salesorderheader
    GROUP BY salespersonid, strftime('%Y', orderdate)
),
quota AS (
    SELECT
        BusinessEntityID              AS salesperson,
        strftime('%Y', QuotaDate)     AS year,
        SUM(SalesQuota)               AS total_quota
    FROM SalesPersonQuotaHistory
    GROUP BY BusinessEntityID, strftime('%Y', QuotaDate)
)
SELECT
    s.salesperson,
    s.year,
    ROUND(s.total_sales - q.total_quota, 4) AS difference
FROM sales AS s
JOIN quota AS q
  ON s.salesperson = q.salesperson
 AND s.year        = q.year
ORDER BY s.salesperson, s.year;