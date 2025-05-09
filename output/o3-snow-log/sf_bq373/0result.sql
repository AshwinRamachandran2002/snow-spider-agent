/* 1) pick all invoice lines that belong to invoices dated in 2014
   2) total the line amounts per customer for the whole year
   3) divide by 12 to get that customer’s average monthly spend
   4) take the median of those average-monthly values            */
WITH per_customer AS (
    SELECT
        inv."CustomerID",
        SUM(COALESCE(line."ExtendedPrice",0))                AS total_year_2014,
        SUM(COALESCE(line."ExtendedPrice",0)) / 12.0         AS avg_monthly_spend
    FROM  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES     inv
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICELINES  line
          ON line."InvoiceID" = inv."InvoiceID"
    WHERE inv."InvoiceDate" >= '2014-01-01'
      AND inv."InvoiceDate" <  '2015-01-01'
    GROUP BY inv."CustomerID"
)
SELECT MEDIAN(avg_monthly_spend) AS median_average_monthly_spending_2014
FROM   per_customer
WHERE  avg_monthly_spend > 0;   -- consider only customers who spent something