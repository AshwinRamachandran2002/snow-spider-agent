WITH country_customers AS (
    SELECT
        "Country",
        COUNT(*) AS customer_count
    FROM "customers"
    GROUP BY "Country"
    HAVING COUNT(*) > 4
),
country_sales AS (
    SELECT
        i."BillingCountry"   AS Country,
        SUM(i."Total")       AS total_sales
    FROM "invoices" i
    JOIN country_customers cc
      ON cc."Country" = i."BillingCountry"
    GROUP BY i."BillingCountry"
),
ordered_sales AS (
    SELECT
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales)          AS rn,
        COUNT(*)    OVER ()                               AS cnt
    FROM country_sales
)
SELECT
    ROUND(AVG(total_sales), 4) AS median_total_sales
FROM ordered_sales
WHERE rn IN ( (cnt + 1) / 2, (cnt + 2) / 2 );