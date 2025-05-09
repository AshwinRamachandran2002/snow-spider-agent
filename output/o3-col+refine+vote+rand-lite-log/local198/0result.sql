WITH hi_cust_countries AS (
    SELECT Country
    FROM customers
    GROUP BY Country
    HAVING COUNT(*) > 4
), invoice_totals AS (
    SELECT Total
    FROM invoices
    WHERE BillingCountry IN (SELECT Country FROM hi_cust_countries)
), ordered_totals AS (
    SELECT Total,
           ROW_NUMBER() OVER (ORDER BY Total) AS rn,
           COUNT(*)  OVER ()                 AS cnt
    FROM invoice_totals
)
SELECT ROUND(AVG(Total), 4) AS median_total_sales
FROM ordered_totals
WHERE rn IN ( (cnt + 1) / 2,
              (cnt + 2) / 2 );