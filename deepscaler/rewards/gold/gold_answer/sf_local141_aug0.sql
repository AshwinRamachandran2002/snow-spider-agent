-- Task: For each salesperson and each year, compute the total sales amount by summing "totaldue" from the SALESORDERHEADER table (based on "orderdate") and the total sales quota by summing "SalesQuota" from the SALESPERSONQUOTAHISTORY table (based on "QuotaDate"). Calculate the difference between their total sales and sales quota for each year. Include all salespersons and years where there is either sales or quota data by performing a full outer join on "SalesPersonID" and "Year". Treat any missing sales or quota data as zero. Organize the results by salesperson and year.

SELECT
    COALESCE(sales_per_year."SalesPersonID", quota_per_year."SalesPersonID") AS "SalesPersonID",
    COALESCE(sales_per_year."Year", quota_per_year."Year") AS "Year",
    ROUND(sales_per_year."TotalSales", 4) AS "TotalSales",
    ROUND(quota_per_year."SalesQuota", 4) AS "SalesQuota",
    ROUND(
        COALESCE(sales_per_year."TotalSales", 0) - COALESCE(quota_per_year."SalesQuota", 0),
        4
    ) AS "Difference"
FROM
    (
        SELECT
            CAST("salespersonid" AS NUMBER) AS "SalesPersonID",
            DATE_PART(YEAR, TRY_TO_DATE("orderdate", 'YYYY-MM-DD HH24:MI:SS')) AS "Year",
            SUM(TRY_TO_DOUBLE("totaldue")) AS "TotalSales"
        FROM ADVENTUREWORKS.ADVENTUREWORKS.SALESORDERHEADER
        WHERE
            "salespersonid" IS NOT NULL
            AND "salespersonid" <> ''
            AND TRY_TO_NUMBER("salespersonid") IS NOT NULL
            AND TRY_TO_DATE("orderdate", 'YYYY-MM-DD HH24:MI:SS') IS NOT NULL
            AND TRY_TO_DOUBLE("totaldue") IS NOT NULL
        GROUP BY
            CAST("salespersonid" AS NUMBER),
            DATE_PART(YEAR, TRY_TO_DATE("orderdate", 'YYYY-MM-DD HH24:MI:SS'))
    ) AS sales_per_year
FULL OUTER JOIN
    (
        SELECT
            "BusinessEntityID" AS "SalesPersonID",
            DATE_PART(YEAR, TRY_TO_DATE("QuotaDate", 'YYYY-MM-DD HH24:MI:SS')) AS "Year",
            SUM(TRY_TO_DOUBLE("SalesQuota")) AS "SalesQuota"
        FROM ADVENTUREWORKS.ADVENTUREWORKS.SALESPERSONQUOTAHISTORY
        WHERE
            TRY_TO_DATE("QuotaDate", 'YYYY-MM-DD HH24:MI:SS') IS NOT NULL
            AND TRY_TO_DOUBLE("SalesQuota") IS NOT NULL
        GROUP BY
            "BusinessEntityID",
            DATE_PART(YEAR, TRY_TO_DATE("QuotaDate", 'YYYY-MM-DD HH24:MI:SS'))
    ) AS quota_per_year
ON
    sales_per_year."SalesPersonID" = quota_per_year."SalesPersonID"
    AND sales_per_year."Year" = quota_per_year."Year"
ORDER BY
    COALESCE(sales_per_year."SalesPersonID", quota_per_year."SalesPersonID"),
    COALESCE(sales_per_year."Year", quota_per_year."Year");