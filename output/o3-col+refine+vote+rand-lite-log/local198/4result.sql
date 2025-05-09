WITH qualifying_countries AS (
    SELECT "Country"
    FROM   "customers"
    GROUP  BY "Country"
    HAVING COUNT(*) > 4
),
ordered_totals AS (
    SELECT i."Total",
           ROW_NUMBER() OVER (ORDER BY i."Total") AS rn,
           COUNT(*)  OVER ()                     AS cnt
    FROM   "invoices"  i
    JOIN   "customers" c ON c."CustomerId" = i."CustomerId"
    WHERE  c."Country" IN (SELECT "Country" FROM qualifying_countries)
)
SELECT AVG("Total") AS "median_total_sales"
FROM   ordered_totals
WHERE  rn IN ( (cnt + 1) / 2,
               (cnt + 2) / 2 );