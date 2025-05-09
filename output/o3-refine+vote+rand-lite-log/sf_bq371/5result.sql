WITH "INVOICE_TOTALS" AS (
    SELECT
        i."InvoiceID",
        TO_DATE(i."InvoiceDate")                    AS "InvoiceDate",
        SUM(il."UnitPrice" * il."Quantity")        AS "InvoiceTotal"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"       i
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"   il
          ON i."InvoiceID" = il."InvoiceID"
    WHERE YEAR(TO_DATE(i."InvoiceDate")) = 2013
    GROUP BY i."InvoiceID", i."InvoiceDate"
),
"QUARTER_AVERAGES" AS (
    SELECT
        DATE_PART('QUARTER', "InvoiceDate")        AS "Quarter",
        AVG("InvoiceTotal")                        AS "AvgInvoiceValue"
    FROM "INVOICE_TOTALS"
    GROUP BY DATE_PART('QUARTER', "InvoiceDate")
)
SELECT
    MAX("AvgInvoiceValue") - MIN("AvgInvoiceValue")    AS "Difference_Max_Min_Avg"
FROM "QUARTER_AVERAGES";