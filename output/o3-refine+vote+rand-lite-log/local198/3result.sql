WITH qualifying_countries AS (
    SELECT Country
    FROM customers
    GROUP BY Country
    HAVING COUNT(*) > 4
),
filtered_invoices AS (
    SELECT i.Total
    FROM invoices AS i
    JOIN customers AS c ON c.CustomerId = i.CustomerId
    WHERE c.Country IN (SELECT Country FROM qualifying_countries)
),
ordered_totals AS (
    SELECT
        Total,
        ROW_NUMBER() OVER (ORDER BY Total) AS rn,
        COUNT(*)  OVER ()                  AS cnt
    FROM filtered_invoices
)
SELECT ROUND(AVG(Total), 4) AS median_total_sales
FROM   ordered_totals
WHERE  rn IN ( (cnt + 1) / 2,  (cnt + 2) / 2 );