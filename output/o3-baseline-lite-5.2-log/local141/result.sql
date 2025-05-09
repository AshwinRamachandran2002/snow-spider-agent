WITH annual_sales AS (
    /* yearly total sales for every salesperson (based on TotalDue) */
    SELECT
        salespersonid                        AS salesperson_id,
        strftime('%Y', orderdate)            AS year,
        SUM(totaldue)                        AS total_sales
    FROM salesorderheader
    WHERE salespersonid IS NOT NULL
    GROUP BY salespersonid, year
),
annual_quota AS (
    /* yearly quota (can be several quota entries per year → SUM) */
    SELECT
        BusinessEntityID                     AS salesperson_id,
        strftime('%Y', QuotaDate)            AS year,
        SUM(SalesQuota)                      AS total_quota
    FROM SalesPersonQuotaHistory
    GROUP BY BusinessEntityID, year
),
combined AS (
    /* LEFT part: sales that have (or may not have) matching quota */
    SELECT
        s.salesperson_id,
        s.year,
        s.total_sales,
        IFNULL(q.total_quota, 0)             AS total_quota
    FROM annual_sales AS s
    LEFT JOIN annual_quota AS q
           ON s.salesperson_id = q.salesperson_id
          AND s.year           = q.year
    
    UNION ALL
    
    /* RIGHT‑only part: quotas that have no matching sales */
    SELECT
        q.salesperson_id,
        q.year,
        0                                    AS total_sales,
        q.total_quota
    FROM annual_quota AS q
    LEFT JOIN annual_sales AS s
           ON s.salesperson_id = q.salesperson_id
          AND s.year           = q.year
    WHERE s.salesperson_id IS NULL           -- keep only quota‑only rows
)

SELECT
    salesperson_id,
    year,
    total_sales,
    total_quota,
    total_sales - total_quota                AS difference
FROM combined
ORDER BY salesperson_id, year;