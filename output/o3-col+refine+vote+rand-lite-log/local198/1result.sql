WITH big_countries AS (
    SELECT "Country"
    FROM   "customers"
    GROUP  BY "Country"
    HAVING COUNT(*) > 4
),
sales_by_country AS (
    SELECT "BillingCountry"            AS "Country",
           SUM("Total")                AS total_sales
    FROM   "invoices"
    GROUP  BY "BillingCountry"
),
ranked AS (
    SELECT total_sales,
           ROW_NUMBER() OVER (ORDER BY total_sales) AS rn,
           COUNT(*)    OVER ()                      AS cnt
    FROM   sales_by_country
    WHERE  "Country" IN (SELECT "Country"
                         FROM   big_countries)
)
SELECT AVG(total_sales) AS median_total_sales
FROM   ranked
WHERE  rn IN ( (cnt + 1) / 2,
               (cnt + 2) / 2 );