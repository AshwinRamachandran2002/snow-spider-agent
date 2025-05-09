WITH qualifying_countries AS (
    SELECT Country
    FROM customers
    GROUP BY Country
    HAVING COUNT(*) > 4
),
country_sales AS (
    SELECT c.Country,
           SUM(i.Total) AS total_sales
    FROM customers c
    JOIN invoices  i ON i.CustomerId = c.CustomerId
    WHERE c.Country IN (SELECT Country FROM qualifying_countries)
    GROUP BY c.Country
),
ordered_totals AS (
    SELECT 
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales) AS rn,
        COUNT(*)  OVER ()                        AS cnt
    FROM country_sales
)
SELECT AVG(total_sales) AS median_total_sales
FROM   ordered_totals
WHERE  rn IN ( (cnt + 1) / 2, (cnt + 2) / 2 );