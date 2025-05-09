WITH invoice_totals AS (
    SELECT
        iv."InvoiceID",
        DATE_PART('QUARTER', TO_DATE(iv."InvoiceDate"))             AS quarter_num,
        SUM(il."UnitPrice" * il."Quantity")                         AS invoice_total
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES     iv
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICELINES il
      ON iv."InvoiceID" = il."InvoiceID"
    WHERE DATE_PART('YEAR', TO_DATE(iv."InvoiceDate")) = 2013
    GROUP BY iv."InvoiceID",
             DATE_PART('QUARTER', TO_DATE(iv."InvoiceDate"))
), quarter_avgs AS (
    SELECT
        quarter_num,
        AVG(invoice_total) AS avg_invoice_value
    FROM invoice_totals
    GROUP BY quarter_num
)
SELECT
    ROUND(MAX(avg_invoice_value) - MIN(avg_invoice_value), 4) AS difference
FROM quarter_avgs;