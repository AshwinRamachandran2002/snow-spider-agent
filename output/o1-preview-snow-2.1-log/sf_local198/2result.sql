WITH TopCountries AS (
    SELECT "Country"
    FROM CHINOOK.CHINOOK.CUSTOMERS
    GROUP BY "Country"
    HAVING COUNT("CustomerId") > 4
),
CountrySales AS (
    SELECT c."Country", SUM(i."Total") AS "TotalSales"
    FROM CHINOOK.CHINOOK.INVOICES i
    JOIN CHINOOK.CHINOOK.CUSTOMERS c ON c."CustomerId" = i."CustomerId"
    WHERE c."Country" IN (SELECT "Country" FROM TopCountries)
    GROUP BY c."Country"
)
SELECT ROUND(MEDIAN("TotalSales"), 4) AS "Median_Total_Sales"
FROM CountrySales;