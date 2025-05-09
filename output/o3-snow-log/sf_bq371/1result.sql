WITH invoice_totals AS (
    -- total value of each invoice in 2013
    SELECT
        i."InvoiceID",
        DATE_PART('quarter', TO_DATE(i."InvoiceDate",'YYYY-MM-DD'))       AS quarter,
        SUM(il."UnitPrice" * il."Quantity")                               AS invoice_value
    FROM  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      i
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"  il
          ON i."InvoiceID" = il."InvoiceID"
    WHERE DATE_PART('year', TO_DATE(i."InvoiceDate",'YYYY-MM-DD')) = 2013
    GROUP BY i."InvoiceID", quarter
),
quarter_averages AS (
    -- average invoice value per quarter
    SELECT
        quarter,
        AVG(invoice_value) AS avg_invoice_value
    FROM invoice_totals
    GROUP BY quarter
)
-- difference between maximum and minimum of the quarterly averages
SELECT
    MAX(avg_invoice_value) - MIN(avg_invoice_value) AS diff_max_min_avg_invoice_value
FROM quarter_averages;