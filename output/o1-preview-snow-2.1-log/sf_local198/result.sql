WITH countries_with_more_than_four_customers AS (
    SELECT "Country"
    FROM CHINOOK.CHINOOK.CUSTOMERS
    GROUP BY "Country"
    HAVING COUNT(*) > 4
),
total_sales_per_country AS (
    SELECT "BillingCountry", SUM("Total") AS "Total_Sales"
    FROM CHINOOK.CHINOOK.INVOICES
    WHERE "BillingCountry" IN (
        SELECT "Country" FROM countries_with_more_than_four_customers
    )
    GROUP BY "BillingCountry"
)
SELECT ROUND(
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "Total_Sales" ASC NULLS LAST), 4
) AS "Median_Total_Sales"
FROM total_sales_per_country;