WITH customer_counts AS (
    SELECT Country,
           COUNT(*) AS num_customers
    FROM customers
    GROUP BY Country
),
selected_countries AS (
    SELECT Country
    FROM customer_counts
    WHERE num_customers > 4
),
sales_per_country AS (
    SELECT i.BillingCountry AS Country,
           SUM(i.Total)      AS total_sales
    FROM invoices AS i
    JOIN selected_countries AS sc
      ON sc.Country = i.BillingCountry
    GROUP BY i.BillingCountry
),
ordered_sales AS (
    SELECT total_sales,
           ROW_NUMBER() OVER (ORDER BY total_sales) AS rn,
           COUNT(*)  OVER ()                        AS cnt
    FROM sales_per_country
)
SELECT ROUND(AVG(total_sales), 4) AS median_total_sales
FROM ordered_sales
WHERE rn IN ( (cnt + 1) / 2, (cnt + 2) / 2 );