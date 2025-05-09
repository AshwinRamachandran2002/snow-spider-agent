WITH country_customer_counts AS (
    SELECT "Country"
    FROM   "customers"
    GROUP BY "Country"
    HAVING COUNT(*) > 4
),
qualifying_invoices AS (
    SELECT i."Total"
    FROM   "invoices"  AS i
    JOIN   "customers" AS c USING ("CustomerId")
    WHERE  c."Country" IN (SELECT "Country"
                           FROM   country_customer_counts)
),
ordered_totals AS (
    SELECT q."Total",
           ROW_NUMBER() OVER (ORDER BY q."Total") AS rn,
           COUNT(*)   OVER ()                     AS cnt
    FROM   qualifying_invoices AS q
)
SELECT ROUND(AVG("Total"), 4) AS "median_total_sales"
FROM   ordered_totals
WHERE  rn IN ( (cnt + 1) / 2, (cnt + 2) / 2 );