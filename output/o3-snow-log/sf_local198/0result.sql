WITH customer_counts AS (
    SELECT 
        "Country",
        COUNT(*) AS "customer_count"
    FROM CHINOOK.CHINOOK.CUSTOMERS
    GROUP BY "Country"
),
countries_with_many_customers AS (
    SELECT "Country"
    FROM customer_counts
    WHERE "customer_count" > 4
),
country_sales AS (
    SELECT 
        c."Country",
        SUM(i."Total") AS "total_sales"
    FROM CHINOOK.CHINOOK.INVOICES i
    JOIN CHINOOK.CHINOOK.CUSTOMERS c
      ON i."CustomerId" = c."CustomerId"
    WHERE c."Country" IN (SELECT "Country" FROM countries_with_many_customers)
    GROUP BY c."Country"
)
SELECT 
    MEDIAN("total_sales") AS "median_total_sales"
FROM country_sales;