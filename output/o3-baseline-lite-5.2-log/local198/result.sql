WITH qual_countries AS (
    SELECT Country
    FROM customers
    GROUP BY Country
    HAVING COUNT(*) > 4
),
sales AS (
    SELECT i.Total
    FROM invoices AS i
    JOIN qual_countries AS q
      ON q.Country = i.BillingCountry
),
ordered AS (
    SELECT
        Total,
        ROW_NUMBER() OVER (ORDER BY Total) AS rn,
        COUNT(*)  OVER ()                  AS cnt
    FROM sales
)
SELECT AVG(Total) AS median_total
FROM ordered
WHERE rn IN ( (cnt + 1) / 2, (cnt + 2) / 2 );