WITH annual_sales AS (              -- yearly sales taken from SalesOrderHeader
    SELECT
        salespersonid                               AS salesperson_id,
        CAST(strftime('%Y', orderdate) AS INTEGER)  AS year,
        SUM(subtotal)                               AS total_sales
    FROM salesorderheader
    WHERE salespersonid IS NOT NULL
    GROUP BY salespersonid,
             CAST(strftime('%Y', orderdate) AS INTEGER)
),
annual_quota AS (                   -- yearly quota summed from SalesPersonQuotaHistory
    SELECT
        BusinessEntityID                              AS salesperson_id,
        CAST(strftime('%Y', QuotaDate) AS INTEGER)    AS year,
        SUM(SalesQuota)                               AS annual_quota
    FROM SalesPersonQuotaHistory
    GROUP BY BusinessEntityID,
             CAST(strftime('%Y', QuotaDate) AS INTEGER)
),
all_keys AS (                       -- every (salesperson,year) pair that appears in either table
    SELECT salesperson_id, year FROM annual_sales
    UNION
    SELECT salesperson_id, year FROM annual_quota
)
SELECT
    k.salesperson_id,
    k.year,
    ROUND(COALESCE(s.total_sales ,0),4)   AS total_sales,
    ROUND(COALESCE(q.annual_quota,0),4)   AS annual_quota,
    ROUND(COALESCE(s.total_sales ,0) - 
          COALESCE(q.annual_quota,0),4)   AS difference
FROM all_keys k
LEFT JOIN annual_sales  s ON s.salesperson_id = k.salesperson_id AND s.year = k.year
LEFT JOIN annual_quota  q ON q.salesperson_id = k.salesperson_id AND q.year = k.year
ORDER BY k.salesperson_id, k.year;