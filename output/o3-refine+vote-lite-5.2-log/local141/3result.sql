WITH combined AS (
    /* yearly total sales taken from sales orders */
    SELECT
        salespersonid                    AS businessentityid,
        CAST(strftime('%Y', orderdate) AS INTEGER) AS year,
        SUM(totaldue)                   AS total_sales,
        0.0                             AS annual_quota
    FROM salesorderheader
    WHERE salespersonid IS NOT NULL
    GROUP BY salespersonid, year

    UNION ALL

    /* yearly sales‑quota figures taken from quota history */
    SELECT
        BusinessEntityID                AS businessentityid,
        CAST(strftime('%Y', QuotaDate) AS INTEGER) AS year,
        0.0                             AS total_sales,
        SUM(SalesQuota)                 AS annual_quota
    FROM SalesPersonQuotaHistory
    GROUP BY BusinessEntityID, year
)

SELECT
    businessentityid,
    year,
    ROUND(SUM(total_sales), 4)        AS total_sales,
    ROUND(SUM(annual_quota), 4)       AS annual_quota,
    ROUND(SUM(total_sales) - SUM(annual_quota), 4) AS difference
FROM combined
GROUP BY businessentityid, year
ORDER BY businessentityid, year;