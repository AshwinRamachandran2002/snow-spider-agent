WITH sales AS (
    SELECT
        salespersonid                   AS id,
        strftime('%Y', orderdate)       AS year,
        SUM(totaldue)                   AS sales
    FROM salesorderheader
    GROUP BY salespersonid, year
),
quota AS (
    SELECT
        BusinessEntityID                AS id,
        strftime('%Y', QuotaDate)       AS year,
        SUM(SalesQuota)                 AS quota
    FROM "SalesPersonQuotaHistory"
    GROUP BY BusinessEntityID, year
),
combined AS (
    SELECT id, year, sales, 0     AS quota FROM sales
    UNION ALL
    SELECT id, year, 0        AS sales, quota FROM quota
),
diff AS (
    SELECT
        id         AS salesperson,
        year,
        SUM(sales) AS total_sales,
        SUM(quota) AS total_quota
    FROM combined
    GROUP BY id, year
)
SELECT
    salesperson,
    year,
    ROUND(total_sales - total_quota, 4) AS difference
FROM diff
ORDER BY salesperson, year;