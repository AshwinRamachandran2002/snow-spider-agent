WITH countries_with_many_customers AS (
    SELECT "Country"
    FROM CHINOOK.CHINOOK.CUSTOMERS
    GROUP BY "Country"
    HAVING COUNT(*) > 4
),
country_sales AS (
    SELECT "BillingCountry" AS "Country",
           SUM("Total") AS "Total_Sales"
    FROM CHINOOK.CHINOOK.INVOICES
    WHERE "BillingCountry" IN (SELECT "Country" FROM countries_with_many_customers)
    GROUP BY "BillingCountry"
)
SELECT ROUND(MEDIAN("Total_Sales"), 4) AS "median_total_sales"
FROM country_sales;