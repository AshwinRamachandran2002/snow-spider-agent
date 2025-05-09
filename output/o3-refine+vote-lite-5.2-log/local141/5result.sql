WITH
/* yearly total sales (invoice amount) per salesperson */
sales AS (
    SELECT
        salespersonid                                   AS salesperson_id,
        strftime('%Y', orderdate)                       AS sales_year,
        SUM(totaldue)                                   AS total_sales
    FROM salesorderheader
    WHERE salespersonid IS NOT NULL
    GROUP BY salespersonid, strftime('%Y', orderdate)
),

/* yearly quota per salesperson (sum of all quota rows of that year) */
quota AS (
    SELECT
        BusinessEntityID                                AS salesperson_id,
        strftime('%Y', QuotaDate)                       AS sales_year,
        SUM(SalesQuota)                                 AS annual_quota
    FROM SalesPersonQuotaHistory
    GROUP BY BusinessEntityID, strftime('%Y', QuotaDate)
),

/* list of every salesperson‑year that appears in either table */
years AS (
    SELECT salesperson_id, sales_year FROM sales
    UNION
    SELECT salesperson_id, sales_year FROM quota
)

SELECT
    y.salesperson_id,
    y.sales_year                                       AS year,
    COALESCE(s.total_sales, 0)                         AS total_sales,
    COALESCE(q.annual_quota, 0)                        AS annual_quota,
    COALESCE(s.total_sales, 0) - COALESCE(q.annual_quota, 0)
                                                      AS difference
FROM years y
LEFT JOIN sales s
       ON s.salesperson_id = y.salesperson_id
      AND s.sales_year     = y.sales_year
LEFT JOIN quota q
       ON q.salesperson_id = y.salesperson_id
      AND q.sales_year     = y.sales_year
ORDER BY y.salesperson_id, y.sales_year;