WITH invoice_lines_2014 AS (
    SELECT  inv."CustomerID",
            il."ExtendedPrice"
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     inv
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
           ON inv."InvoiceID" = il."InvoiceID"
    WHERE   inv."InvoiceDate" >= '2014-01-01'
      AND   inv."InvoiceDate" <  '2015-01-01'
),
customer_avg_monthly AS (
    SELECT  "CustomerID",
            SUM("ExtendedPrice") / 12.0 AS avg_monthly_spend   -- average over the 12 months of 2014
    FROM    invoice_lines_2014
    GROUP BY "CustomerID"
)
SELECT  MEDIAN(avg_monthly_spend) AS "MEDIAN_AVG_MONTHLY_SPEND_2014"
FROM    customer_avg_monthly;