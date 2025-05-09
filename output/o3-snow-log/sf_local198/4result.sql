WITH "customers_per_country" AS (
    SELECT 
        "Country",
        COUNT(*) AS "customer_count"
    FROM CHINOOK.CHINOOK.CUSTOMERS
    GROUP BY "Country"
    HAVING COUNT(*) > 4               -- only countries having more than 4 customers
),
"country_sales" AS (
    SELECT
        i."BillingCountry"   AS "Country",
        SUM(i."Total")       AS "total_sales"
    FROM CHINOOK.CHINOOK.INVOICES i
    JOIN "customers_per_country" c
          ON i."BillingCountry" = c."Country"
    GROUP BY i."BillingCountry"
)
SELECT 
    MEDIAN("total_sales") AS "median_total_sales"
FROM "country_sales";