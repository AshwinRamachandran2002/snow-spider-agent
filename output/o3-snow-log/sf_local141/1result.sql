WITH sales_per_year AS (
    SELECT
        CAST("salespersonid" AS NUMBER)                AS "BusinessEntityID",
        YEAR(TO_TIMESTAMP("orderdate"))               AS "SalesYear",
        SUM("totaldue")                               AS "TotalSales"
    FROM ADVENTUREWORKS.ADVENTUREWORKS.SALESORDERHEADER
    WHERE "salespersonid" IS NOT NULL 
          AND TRIM("salespersonid") <> ''
    GROUP BY
        CAST("salespersonid" AS NUMBER),
        YEAR(TO_TIMESTAMP("orderdate"))
),
quota_per_year AS (
    SELECT
        "BusinessEntityID",
        YEAR(TO_TIMESTAMP("QuotaDate"))               AS "QuotaYear",
        SUM("SalesQuota")                             AS "AnnualQuota"
    FROM ADVENTUREWORKS.ADVENTUREWORKS.SALESPERSONQUOTAHISTORY
    GROUP BY
        "BusinessEntityID",
        YEAR(TO_TIMESTAMP("QuotaDate"))
)
SELECT
    COALESCE(s."BusinessEntityID", q."BusinessEntityID")          AS "BusinessEntityID",
    COALESCE(s."SalesYear"      , q."QuotaYear")                  AS "Year",
    s."TotalSales"                                                AS "TotalSales",
    q."AnnualQuota"                                               AS "AnnualQuota",
    COALESCE(s."TotalSales", 0) - COALESCE(q."AnnualQuota", 0)    AS "SalesMinusQuota"
FROM sales_per_year s
FULL OUTER JOIN quota_per_year q
       ON s."BusinessEntityID" = q."BusinessEntityID"
      AND s."SalesYear"        = q."QuotaYear"
ORDER BY
    "BusinessEntityID",
    "Year";