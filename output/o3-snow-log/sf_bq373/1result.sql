/*  Median of customers' average monthly spending in 2014  */

WITH all_customers AS (          -- every customer in the system
    SELECT "CustomerID"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_CUSTOMERS
),

invoice_totals_2014 AS (         -- total extended price per customer in 2014
    SELECT  i."CustomerID",
            SUM(il."ExtendedPrice") AS total_2014
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICELINES  il
            JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES i
              ON il."InvoiceID" = i."InvoiceID"
    WHERE   TO_DATE(i."InvoiceDate") >= '2014-01-01'
      AND   TO_DATE(i."InvoiceDate") <  '2015-01-01'
    GROUP BY i."CustomerID"
),

avg_monthly_per_customer AS (    -- divide yearly total by 12 months
    SELECT  c."CustomerID",
            COALESCE(t.total_2014, 0) / 12.0 AS avg_monthly_spend
    FROM    all_customers        c
            LEFT JOIN invoice_totals_2014 t
              ON c."CustomerID" = t."CustomerID"
)

SELECT  MEDIAN(avg_monthly_spend)  AS median_of_average_monthly_spending
FROM    avg_monthly_per_customer;