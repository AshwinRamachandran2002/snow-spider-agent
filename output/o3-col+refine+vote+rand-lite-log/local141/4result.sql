WITH yearly_sales AS (
    SELECT 
        salespersonid                     AS salesperson_id,
        substr(orderdate, 1, 4)           AS year,
        SUM(totaldue)                     AS total_sales
    FROM salesorderheader
    WHERE salespersonid IS NOT NULL
    GROUP BY salespersonid,
             substr(orderdate, 1, 4)
),
yearly_quota AS (
    SELECT 
        "BusinessEntityID"                AS salesperson_id,
        substr("QuotaDate", 1, 4)         AS year,
        SUM("SalesQuota")                 AS annual_quota
    FROM "SalesPersonQuotaHistory"
    GROUP BY "BusinessEntityID",
             substr("QuotaDate", 1, 4)
)
SELECT 
    s.salesperson_id,
    s.year,
    s.total_sales,
    q.annual_quota,
    s.total_sales - q.annual_quota        AS difference_to_quota
FROM yearly_sales AS s
JOIN yearly_quota AS q
  ON s.salesperson_id = q.salesperson_id
 AND s.year           = q.year
ORDER BY s.salesperson_id,
         s.year;