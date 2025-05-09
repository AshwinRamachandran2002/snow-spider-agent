WITH EligibleCountries AS (
    SELECT "Country"
    FROM "CHINOOK"."CHINOOK"."CUSTOMERS"
    GROUP BY "Country"
    HAVING COUNT(*) > 4
),
CountrySales AS (
    SELECT c."Country", SUM(i."Total") AS "Total_Sales"
    FROM "CHINOOK"."CHINOOK"."CUSTOMERS" c
    JOIN "CHINOOK"."CHINOOK"."INVOICES" i ON c."CustomerId" = i."CustomerId"
    WHERE c."Country" IN (SELECT "Country" FROM EligibleCountries)
    GROUP BY c."Country"
)
SELECT MEDIAN("Total_Sales") AS "Median_Total_Sales"
FROM CountrySales;