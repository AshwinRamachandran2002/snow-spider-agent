WITH countries_with_many_customers AS (
    SELECT 
        "Country"
    FROM CHINOOK.CHINOOK.CUSTOMERS
    GROUP BY "Country"
    HAVING COUNT(*) > 4
)
SELECT 
    MEDIAN("Total") AS median_total_sales
FROM CHINOOK.CHINOOK.INVOICES AS inv
JOIN countries_with_many_customers AS c
  ON inv."BillingCountry" = c."Country";