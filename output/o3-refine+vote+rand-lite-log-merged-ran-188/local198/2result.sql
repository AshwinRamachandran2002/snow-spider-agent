WITH countries_with_many_customers AS (
    SELECT "Country"
    FROM "customers"
    GROUP BY "Country"
    HAVING COUNT(*) > 4
),
country_sales AS (
    SELECT "BillingCountry" AS Country,
           SUM("Total")     AS TotalSales
    FROM "invoices"
    WHERE "BillingCountry" IN (SELECT "Country" FROM countries_with_many_customers)
    GROUP BY "BillingCountry"
),
ordered_sales AS (
    SELECT TotalSales,
           ROW_NUMBER() OVER (ORDER BY TotalSales) AS rn,
           COUNT(*)  OVER ()                       AS cnt
    FROM country_sales
)
SELECT ROUND(AVG(TotalSales), 4) AS median_total_sales
FROM ordered_sales
WHERE rn IN ( (cnt + 1) / 2, (cnt + 2) / 2 );