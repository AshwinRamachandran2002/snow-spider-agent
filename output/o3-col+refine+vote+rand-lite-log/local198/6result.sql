WITH big_countries AS (
    SELECT "Country"
    FROM "customers"
    GROUP BY "Country"
    HAVING COUNT(*) > 4
),
country_sales AS (
    SELECT i."BillingCountry" AS "Country",
           SUM(i."Total")     AS "total_sales"
    FROM   "invoices" AS i
    JOIN   big_countries bc
           ON i."BillingCountry" = bc."Country"
    GROUP  BY i."BillingCountry"
),
ordered_sales AS (
    SELECT cs."total_sales",
           ROW_NUMBER() OVER (ORDER BY cs."total_sales") AS rn,
           COUNT(*)  OVER ()                              AS cnt
    FROM   country_sales cs
)
SELECT AVG("total_sales") AS "median_total_sales"
FROM   ordered_sales
WHERE  rn IN ( (cnt + 1) / 2,     -- lower middle (and the single middle if odd count)
               (cnt + 2) / 2 );   -- upper middle (same as lower if odd count)