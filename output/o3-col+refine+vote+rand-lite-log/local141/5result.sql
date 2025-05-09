WITH sales AS (
    SELECT
        "salespersonid",
        SUBSTR("orderdate", 1, 4)           AS "year",
        SUM("subtotal")                     AS "annual_sales"
    FROM   "salesorderheader"
    WHERE  "salespersonid" IS NOT NULL
    GROUP  BY "salespersonid", SUBSTR("orderdate", 1, 4)
),
quota AS (
    SELECT
        "BusinessEntityID"                  AS "salespersonid",
        SUBSTR("QuotaDate", 1, 4)           AS "year",
        SUM("SalesQuota")                   AS "annual_quota"
    FROM   "SalesPersonQuotaHistory"
    GROUP  BY "BusinessEntityID", SUBSTR("QuotaDate", 1, 4)
),
combined AS (  -- emulate FULL OUTER JOIN
    SELECT salespersonid, year, annual_sales, 0             AS annual_quota FROM sales
    UNION ALL
    SELECT salespersonid, year, 0             AS annual_sales, annual_quota FROM quota
)
SELECT
    salespersonid,
    year,
    SUM(annual_sales)                       AS annual_sales,
    SUM(annual_quota)                       AS annual_quota,
    SUM(annual_sales) - SUM(annual_quota)   AS sales_minus_quota
FROM   combined
GROUP  BY salespersonid, year
ORDER  BY salespersonid, year;