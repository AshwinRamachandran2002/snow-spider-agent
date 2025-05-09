WITH countries_with_many_customers AS (
    SELECT Country
    FROM customers
    GROUP BY Country
    HAVING COUNT(*) > 4              -- only countries with more than 4 customers
),
country_total_sales AS (
    SELECT  i.BillingCountry AS Country,
            SUM(i.Total)     AS TotalSales
    FROM    invoices i
    WHERE   i.BillingCountry IN (SELECT Country FROM countries_with_many_customers)
    GROUP BY i.BillingCountry        -- total sales per qualified country
),
ordered_sales AS (
    SELECT  TotalSales,
            ROW_NUMBER() OVER (ORDER BY TotalSales)        AS rn,
            COUNT(*)    OVER ()                            AS cnt
    FROM    country_total_sales
)
SELECT  AVG(TotalSales) AS median_total_sales
FROM    ordered_sales
WHERE   rn IN ( CAST((cnt + 1) / 2 AS INTEGER),           -- middle row (odd) …
                CAST((cnt + 2) / 2 AS INTEGER) );         -- … or the two middles (even)