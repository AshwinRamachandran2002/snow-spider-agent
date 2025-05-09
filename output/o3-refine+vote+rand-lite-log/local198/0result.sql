WITH eligible_countries AS (          -- countries having more than 4 customers
    SELECT "Country"
    FROM "customers"
    GROUP BY "Country"
    HAVING COUNT(*) > 4
),
invoices_filtered AS (                -- invoices issued in those countries
    SELECT "Total"
    FROM "invoices"
    WHERE "BillingCountry" IN (SELECT "Country" FROM eligible_countries)
),
ordered_totals AS (                   -- order totals and add row numbers
    SELECT
        "Total",
        ROW_NUMBER() OVER (ORDER BY "Total") AS rn,
        COUNT(*)    OVER ()            AS cnt
    FROM invoices_filtered
)
SELECT ROUND(AVG("Total"), 4) AS median_total
FROM ordered_totals
WHERE rn IN ( (cnt + 1) / 2,          -- middle row(s) – works for odd or even counts
              (cnt + 2) / 2 );