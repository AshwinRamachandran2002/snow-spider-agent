WITH invoice_totals AS (
    SELECT 
        l."InvoiceID",
        SUM(l."UnitPrice" * l."Quantity") AS invoice_total
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" l
    GROUP BY l."InvoiceID"
), invoice_quarters AS (
    SELECT
        it.invoice_total,
        CASE SUBSTR(i."InvoiceDate", 6, 2)
             WHEN '01' THEN 'Q1' WHEN '02' THEN 'Q1' WHEN '03' THEN 'Q1'
             WHEN '04' THEN 'Q2' WHEN '05' THEN 'Q2' WHEN '06' THEN 'Q2'
             WHEN '07' THEN 'Q3' WHEN '08' THEN 'Q3' WHEN '09' THEN 'Q3'
             WHEN '10' THEN 'Q4' WHEN '11' THEN 'Q4' WHEN '12' THEN 'Q4'
        END AS quarter
    FROM invoice_totals it
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES" i
      ON it."InvoiceID" = i."InvoiceID"
    WHERE i."InvoiceDate" LIKE '2013%'
), quarter_avgs AS (
    SELECT 
        quarter,
        AVG(invoice_total) AS avg_invoice_value
    FROM invoice_quarters
    GROUP BY quarter
)
SELECT 
    ROUND(MAX(avg_invoice_value) - MIN(avg_invoice_value), 4) AS difference
FROM quarter_avgs;