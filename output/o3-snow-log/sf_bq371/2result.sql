WITH invoice_totals AS (   -- total value of every invoice
    SELECT 
        il."InvoiceID",
        SUM(il."UnitPrice" * il."Quantity") AS invoice_total
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICELINES il
    GROUP BY il."InvoiceID"
), invoice_dates AS (      -- invoice dates
    SELECT 
        i."InvoiceID",
        TO_DATE(i."InvoiceDate")         AS invoice_date
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES i
), joined AS (             -- keep only 2013 invoices
    SELECT 
        it.invoice_total,
        DATE_PART('quarter', id.invoice_date) AS quarter
    FROM invoice_totals it
    JOIN invoice_dates  id ON it."InvoiceID" = id."InvoiceID"
    WHERE DATE_PART('year', id.invoice_date) = 2013
), quarter_avgs AS (       -- average invoice value per quarter
    SELECT 
        quarter,
        AVG(invoice_total) AS avg_invoice_value
    FROM joined
    GROUP BY quarter
)
SELECT 
    MAX(avg_invoice_value) - MIN(avg_invoice_value) 
        AS difference_between_max_and_min_avg_invoice_values
FROM quarter_avgs;