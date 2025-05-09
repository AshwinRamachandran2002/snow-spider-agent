WITH EligibleCountries AS (
    SELECT "Country"
    FROM "customers"
    GROUP BY "Country"
    HAVING COUNT(*) > 4
),
EligibleInvoices AS (
    SELECT i."Total"
    FROM "invoices" AS i
    JOIN "customers" AS c ON c."CustomerId" = i."CustomerId"
    WHERE c."Country" IN (SELECT "Country" FROM EligibleCountries)
),
OrderedTotals AS (
    SELECT ei."Total",
           ROW_NUMBER() OVER (ORDER BY ei."Total") AS rn,
           COUNT(*) OVER ()                       AS cnt
    FROM EligibleInvoices AS ei
)
SELECT printf('%.4f', AVG("Total")) AS median_total_sales
FROM   OrderedTotals
WHERE  rn IN ((cnt + 1) / 2, (cnt + 2) / 2);