WITH invoice_values AS (   -- total value for every invoice
    SELECT
        "InvoiceID",
        SUM("UnitPrice" * "Quantity") AS invoice_value
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICELINES
    GROUP BY "InvoiceID"
),
invoices_2013 AS (        -- keep only 2013 invoices and their quarter
    SELECT
        QUARTER(TO_DATE(si."InvoiceDate"))       AS qtr,
        iv.invoice_value
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES     si
    JOIN invoice_values                                           iv
          ON si."InvoiceID" = iv."InvoiceID"
    WHERE YEAR(TO_DATE(si."InvoiceDate")) = 2013
),
avg_by_qtr AS (           -- average invoice value per quarter
    SELECT
        qtr,
        AVG(invoice_value) AS avg_invoice_value
    FROM invoices_2013
    GROUP BY qtr
)
SELECT
    MAX(avg_invoice_value) - MIN(avg_invoice_value)  AS difference_max_min_avg
FROM avg_by_qtr;