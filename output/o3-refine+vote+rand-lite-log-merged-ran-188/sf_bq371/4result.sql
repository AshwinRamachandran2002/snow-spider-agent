WITH invoice_totals AS (
    SELECT
        i."InvoiceID",
        QUARTER(TO_DATE(i."InvoiceDate"))                AS "Quarter",
        SUM(il."UnitPrice" * il."Quantity")              AS "InvoiceTotal"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES      i
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICELINES  il
          ON il."InvoiceID" = i."InvoiceID"
    WHERE YEAR(TO_DATE(i."InvoiceDate")) = 2013
    GROUP BY i."InvoiceID",
             QUARTER(TO_DATE(i."InvoiceDate"))
),
quarter_avgs AS (
    SELECT
        "Quarter",
        AVG("InvoiceTotal") AS "AvgInvoiceValue"
    FROM invoice_totals
    GROUP BY "Quarter"
)
SELECT
    MAX("AvgInvoiceValue") - MIN("AvgInvoiceValue") AS "DifferenceBetweenMaxAndMinAvgInvoiceValues"
FROM quarter_avgs;