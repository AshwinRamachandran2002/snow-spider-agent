WITH country_sales AS (
  SELECT c."Country",
         SUM(i."Total")                           AS total_sales
  FROM   "customers" c
  JOIN   "invoices"  i ON i."CustomerId" = c."CustomerId"
  GROUP  BY c."Country"
  HAVING COUNT(DISTINCT c."CustomerId") > 4      -- countries with > 4 customers
),
ordered_sales AS (
  SELECT total_sales,
         ROW_NUMBER() OVER (ORDER BY total_sales) AS rn,
         COUNT(*)  OVER ()                        AS cnt
  FROM   country_sales
)
SELECT ROUND(AVG(total_sales), 4) AS median_total_sales
FROM   ordered_sales
WHERE  rn IN ( (cnt + 1) / 2,          -- lower‑middle row
               (cnt + 2) / 2 );        -- upper‑middle row