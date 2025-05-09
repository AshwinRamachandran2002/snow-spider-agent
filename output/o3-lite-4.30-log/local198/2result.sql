WITH country_filter AS (
  SELECT "Country"
  FROM "customers"
  GROUP BY "Country"
  HAVING COUNT(*) > 4
),
totals AS (
  SELECT "Total"
  FROM "invoices"
  WHERE "BillingCountry" IN (SELECT "Country" FROM country_filter)
),
ordered AS (
  SELECT
    "Total",
    ROW_NUMBER() OVER (ORDER BY "Total") AS rn,
    COUNT(*) OVER ()                     AS cnt
  FROM totals
)
SELECT ROUND(AVG("Total"), 4) AS median_total_sales
FROM   ordered
WHERE  rn IN ( (cnt + 1) / 2, (cnt + 2) / 2 );