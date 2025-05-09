WITH country_sales AS (
    SELECT "BillingCountry" AS "Country",
           SUM("Total")     AS "total_sales"
    FROM "invoices"
    GROUP BY "BillingCountry"
),
customer_counts AS (
    SELECT "Country",
           COUNT(*) AS "num_customers"
    FROM "customers"
    GROUP BY "Country"
),
qualified AS (
    SELECT cs."total_sales"
    FROM country_sales  cs
    JOIN customer_counts cc
      ON cs."Country" = cc."Country"
    WHERE cc."num_customers" > 4
),
ordered AS (
    SELECT "total_sales",
           ROW_NUMBER() OVER (ORDER BY "total_sales") AS rn,
           COUNT(*)  OVER ()                          AS cnt
    FROM qualified
)
SELECT AVG("total_sales") AS "median_total_sales"
FROM ordered
WHERE rn IN ( (cnt + 1) / 2,
              (cnt + 2) / 2 );