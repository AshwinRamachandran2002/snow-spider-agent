WITH invoice_totals AS (
    SELECT
        il."InvoiceID",
        SUM(il."Quantity" * il."UnitPrice") AS invoice_value
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" il
    GROUP BY il."InvoiceID"
),
invoice_dates AS (
    SELECT
        i."InvoiceID",
        TO_DATE(i."InvoiceDate") AS invoice_date
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES" i
)
SELECT
    MAX(avg_invoice_value) - MIN(avg_invoice_value) AS diff_between_max_and_min_avg_invoice_values
FROM (
    SELECT
        QUARTER(d.invoice_date)                               AS qtr,
        AVG(t.invoice_value)                                  AS avg_invoice_value
    FROM invoice_totals t
    JOIN invoice_dates  d ON t."InvoiceID" = d."InvoiceID"
    WHERE YEAR(d.invoice_date) = 2013
    GROUP BY QUARTER(d.invoice_date)
);