WITH "INVOICE_TOTALS" AS (
    SELECT 
        i."InvoiceID",
        TO_DATE(i."InvoiceDate")                                  AS "InvoiceDate",
        SUM(l."UnitPrice" * l."Quantity")                         AS "InvoiceValue"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      i
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"  l
           ON i."InvoiceID" = l."InvoiceID"
    WHERE  EXTRACT(year FROM TO_DATE(i."InvoiceDate")) = 2013
    GROUP  BY i."InvoiceID", i."InvoiceDate"
),
"QUARTER_AVGS" AS (
    SELECT 
        EXTRACT(quarter FROM "InvoiceDate")                       AS "Quarter",
        AVG("InvoiceValue")                                       AS "AvgInvoiceValue"
    FROM   "INVOICE_TOTALS"
    GROUP  BY EXTRACT(quarter FROM "InvoiceDate")
)
SELECT 
    MAX("AvgInvoiceValue") - MIN("AvgInvoiceValue")              AS "Diff_Avg_Invoice_Value"
FROM   "QUARTER_AVGS";