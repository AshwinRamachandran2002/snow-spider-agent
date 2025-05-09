WITH
-- yearly total sales (TotalDue) for every salesperson
annual_sales AS (
    SELECT
        salespersonid,
        strftime('%Y', orderdate) AS year,
        SUM(totaldue)            AS annual_total_sales
    FROM salesorderheader
    WHERE salespersonid IS NOT NULL
    GROUP BY salespersonid, year
),
-- yearly sales quota for every salesperson
annual_quota AS (
    SELECT
        BusinessEntityID         AS salespersonid,
        strftime('%Y', QuotaDate) AS year,
        SUM(SalesQuota)          AS annual_sales_quota
    FROM SalesPersonQuotaHistory
    GROUP BY BusinessEntityID, year
),
-- combine the two sets, keeping rows that appear in either
combined AS (
    /* rows where we have a quota (sales may be missing) */
    SELECT
        q.salespersonid,
        q.year,
        q.annual_sales_quota,
        COALESCE(s.annual_total_sales, 0) AS annual_total_sales
    FROM annual_quota q
    LEFT JOIN annual_sales s
           ON s.salespersonid = q.salespersonid
          AND s.year          = q.year

    UNION ALL

    /* rows with sales but no recorded quota */
    SELECT
        s.salespersonid,
        s.year,
        0                              AS annual_sales_quota,
        s.annual_total_sales
    FROM annual_sales s
    LEFT JOIN annual_quota q
           ON q.salespersonid = s.salespersonid
          AND q.year          = s.year
    WHERE q.salespersonid IS NULL
)
SELECT
    salespersonid,
    year,
    annual_sales_quota,
    annual_total_sales,
    annual_total_sales - annual_sales_quota AS difference_sales_minus_quota
FROM combined
ORDER BY salespersonid, year;