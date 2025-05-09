WITH invoice_totals AS (
    SELECT
        i."InvoiceID",
        QUARTER(TO_DATE(i."InvoiceDate"))      AS quarter_num,
        SUM(l."UnitPrice" * l."Quantity")      AS invoice_total
    FROM  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES      i
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICELINES  l
          ON i."InvoiceID" = l."InvoiceID"
    WHERE YEAR(TO_DATE(i."InvoiceDate")) = 2013
    GROUP BY i."InvoiceID", QUARTER(TO_DATE(i."InvoiceDate"))
),
quarter_avgs AS (
    SELECT
        quarter_num,
        AVG(invoice_total) AS avg_invoice_value
    FROM invoice_totals
    GROUP BY quarter_num
)
SELECT
    MAX(avg_invoice_value) - MIN(avg_invoice_value) AS diff_max_min_avg_invoice_value
FROM quarter_avgs;