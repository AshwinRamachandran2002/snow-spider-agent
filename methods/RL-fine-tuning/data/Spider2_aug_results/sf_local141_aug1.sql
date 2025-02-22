-- Task: Calculate the total sales for each salesperson for each year. Provide the salesperson ID, year, and total sales.
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
ORDER BY
    "SalesPersonID",
    "Year";