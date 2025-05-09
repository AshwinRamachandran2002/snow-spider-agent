WITH big_customer_countries AS (
    SELECT "Country"
    FROM   "customers"
    GROUP  BY "Country"
    HAVING COUNT(*) > 4
),
country_sales AS (
    SELECT i."BillingCountry"         AS "Country",
           SUM(i."Total")             AS "country_total"
    FROM   "invoices" i
    WHERE  i."BillingCountry" IN (SELECT "Country" FROM big_customer_countries)
    GROUP  BY i."BillingCountry"
),
ordered_totals AS (
    SELECT cs."country_total",
           ROW_NUMBER() OVER (ORDER BY cs."country_total") AS rn,
           COUNT(*) OVER ()                                AS cnt
    FROM   country_sales cs
)
SELECT AVG("country_total") AS "median_total_sales"
FROM   ordered_totals
WHERE  rn IN ( (cnt + 1) / 2,
               (cnt + 2) / 2 );