WITH eligible_countries AS (
    SELECT "Country"
    FROM CHINOOK.CHINOOK.CUSTOMERS
    GROUP BY "Country"
    HAVING COUNT(*) > 4
),
country_sales AS (
    SELECT
        "BillingCountry" AS "Country",
        SUM("Total") AS "TotalSales"
    FROM CHINOOK.CHINOOK.INVOICES
    WHERE "BillingCountry" IN (SELECT "Country" FROM eligible_countries)
    GROUP BY "BillingCountry"
)
SELECT
    MEDIAN("TotalSales") AS "MedianTotalSales"
FROM country_sales;