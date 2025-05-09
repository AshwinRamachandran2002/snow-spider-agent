WITH eligible_countries AS (
    SELECT "Country"
    FROM "customers"
    GROUP BY "Country"
    HAVING COUNT(*) > 4
),
country_sales AS (
    SELECT "Total"
    FROM "invoices"
    WHERE "BillingCountry" IN (SELECT "Country" FROM eligible_countries)
),
ordered_sales AS (
    SELECT
        "Total",
        ROW_NUMBER() OVER (ORDER BY "Total") AS rn,
        COUNT(*)  OVER ()                    AS cnt
    FROM country_sales
)
SELECT ROUND(AVG("Total"), 4) AS median_total_sales
FROM ordered_sales
WHERE rn IN ( (cnt + 1) / 2, (cnt + 2) / 2 );