WITH
sales AS (
    SELECT
        "salespersonid"            AS salesperson,
        strftime('%Y',"orderdate") AS year,
        SUM("subtotal")            AS total_sales
    FROM "salesorderheader"
    GROUP BY "salespersonid", strftime('%Y',"orderdate")
),
quota AS (
    SELECT
        "BusinessEntityID"         AS salesperson,
        strftime('%Y',"QuotaDate") AS year,
        SUM("SalesQuota")          AS total_quota
    FROM "SalesPersonQuotaHistory"
    GROUP BY "BusinessEntityID", strftime('%Y',"QuotaDate")
),
combined AS (
    SELECT salesperson, year, total_sales, 0 AS total_quota FROM sales
    UNION ALL
    SELECT salesperson, year, 0 AS total_sales, total_quota FROM quota
)
SELECT
    salesperson,
    year,
    ROUND(SUM(total_sales) - SUM(total_quota), 4) AS difference
FROM combined
GROUP BY salesperson, year
ORDER BY salesperson, year;