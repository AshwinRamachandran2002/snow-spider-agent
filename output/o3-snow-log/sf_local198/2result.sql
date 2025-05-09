WITH customer_counts AS (
    SELECT
        "Country",
        COUNT(*) AS "CustomerCount"
    FROM CHINOOK.CHINOOK.CUSTOMERS
    GROUP BY "Country"
),
country_sales AS (
    SELECT
        "BillingCountry" AS "Country",
        SUM("Total") AS "TotalSales"
    FROM CHINOOK.CHINOOK.INVOICES
    GROUP BY "BillingCountry"
)
SELECT
    ROUND(MEDIAN("TotalSales"), 4) AS "MedianTotalSales"
FROM country_sales cs
JOIN customer_counts cc
      ON cs."Country" = cc."Country"
WHERE cc."CustomerCount" > 4;