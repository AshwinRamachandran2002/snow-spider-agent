WITH customer_counts AS (
    SELECT 
        "Country",
        COUNT(*) AS "cust_count"
    FROM CHINOOK.CHINOOK.CUSTOMERS
    GROUP BY "Country"
),
country_sales AS (
    SELECT 
        "BillingCountry" AS "Country",
        SUM("Total") AS "total_sales"
    FROM CHINOOK.CHINOOK.INVOICES
    GROUP BY "BillingCountry"
)
SELECT 
    MEDIAN("total_sales") AS "median_total_sales"
FROM country_sales cs
JOIN customer_counts cc
  ON cs."Country" = cc."Country"
WHERE cc."cust_count" > 4;