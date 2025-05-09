WITH year_totals AS (   -- yearly totals per customer for 2014
    SELECT  i."CustomerID",
            SUM(l."ExtendedPrice") AS year_total
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"   l
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"       i
           ON l."InvoiceID" = i."InvoiceID"
    WHERE   i."InvoiceDate" >= '2014-01-01'
      AND   i."InvoiceDate" <  '2015-01-01'
    GROUP BY i."CustomerID"
),
avg_monthly AS (        -- average monthly spend per customer
    SELECT  "CustomerID",
            year_total / 12.0 AS avg_monthly_spend   -- divide by the 12 months of 2014
    FROM    year_totals
)
SELECT  MEDIAN(avg_monthly_spend) AS median_avg_monthly_spend
FROM    avg_monthly;