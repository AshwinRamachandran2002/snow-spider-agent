-- Task: Find the total sales per country for countries that have more than four customers.
WITH countries_with_more_than_four_customers AS (
    SELECT "Country"
    FROM CHINOOK.CHINOOK.CUSTOMERS
    GROUP BY "Country"
    HAVING COUNT(*) > 4
)
SELECT "BillingCountry", SUM("Total") AS "Total_Sales"
FROM CHINOOK.CHINOOK.INVOICES
WHERE "BillingCountry" IN (
    SELECT "Country" FROM countries_with_more_than_four_customers
)
GROUP BY "BillingCountry";