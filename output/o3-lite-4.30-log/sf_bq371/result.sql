WITH invoice_totals AS (
    SELECT
        l."InvoiceID",
        SUM(l."Quantity" * l."UnitPrice") AS invoice_total,
        QUARTER(TO_DATE(i."InvoiceDate")) AS qtr
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" l
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"     i
          ON l."InvoiceID" = i."InvoiceID"
    WHERE EXTRACT(year FROM TO_DATE(i."InvoiceDate")) = 2013
    GROUP BY l."InvoiceID", QUARTER(TO_DATE(i."InvoiceDate"))
), quarter_avgs AS (
    SELECT
        qtr,
        AVG(invoice_total) AS avg_invoice_value
    FROM invoice_totals
    GROUP BY qtr
)
SELECT
    ROUND(MAX(avg_invoice_value) - MIN(avg_invoice_value), 4) AS difference
FROM quarter_avgs;