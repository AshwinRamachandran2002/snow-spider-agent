WITH TotalSales AS (
    SELECT
        TRY_TO_NUMBER("salespersonid") AS "SalesPersonID",
        EXTRACT(YEAR FROM CAST("orderdate" AS DATE)) AS "Year",
        SUM("totaldue") AS "TotalSales"
    FROM
        ADVENTUREWORKS.ADVENTUREWORKS.SALESORDERHEADER
    WHERE
        TRY_TO_NUMBER("salespersonid") IS NOT NULL
    GROUP BY
        "SalesPersonID", "Year"
),
AnnualQuotas AS (
    SELECT
        "BusinessEntityID" AS "SalesPersonID",
        EXTRACT(YEAR FROM CAST("QuotaDate" AS DATE)) AS "Year",
        SUM("SalesQuota") AS "SalesQuota"
    FROM
        ADVENTUREWORKS.ADVENTUREWORKS.SALESPERSONQUOTAHISTORY
    GROUP BY
        "SalesPersonID", "Year"
)
SELECT
    ts."SalesPersonID",
    ts."Year",
    ROUND(ts."TotalSales", 4) AS "TotalSales",
    ROUND(aq."SalesQuota", 4) AS "SalesQuota",
    ROUND(ts."TotalSales" - aq."SalesQuota", 4) AS "Difference"
FROM
    TotalSales ts
JOIN
    AnnualQuotas aq
ON
    ts."SalesPersonID" = TRY_TO_NUMBER(aq."SalesPersonID")
    AND ts."Year" = aq."Year"
ORDER BY
    ts."SalesPersonID", ts."Year";