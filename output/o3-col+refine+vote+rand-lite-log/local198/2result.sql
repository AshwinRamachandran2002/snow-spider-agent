WITH customer_counts AS (
    SELECT "Country",
           COUNT(*) AS num_customers
    FROM   "customers"
    GROUP  BY "Country"
    HAVING COUNT(*) > 4
),
country_sales AS (
    SELECT  c."Country",
            SUM(i."Total") AS total_sales
    FROM    "invoices"  AS i
    JOIN    "customers" AS c
      ON    c."CustomerId" = i."CustomerId"
    GROUP   BY c."Country"
),
filtered AS (
    SELECT cs."Country",
           cs.total_sales
    FROM   country_sales  AS cs
    JOIN   customer_counts AS cc
      ON   cs."Country" = cc."Country"
),
ordered AS (
    SELECT total_sales,
           ROW_NUMBER() OVER (ORDER BY total_sales) AS rn,
           COUNT(*)  OVER ()                       AS cnt
    FROM   filtered
)
SELECT AVG(total_sales) AS median_total_sales
FROM   ordered
WHERE  rn IN ( (cnt + 1) / 2,
               (cnt + 2) / 2 );