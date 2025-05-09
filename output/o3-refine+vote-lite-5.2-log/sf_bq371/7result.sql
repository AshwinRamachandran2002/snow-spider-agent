WITH "invoice_totals" AS (
    SELECT
        "InvoiceID",
        SUM("UnitPrice" * "Quantity") AS "InvoiceTotal"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICELINES
    GROUP BY "InvoiceID"
),
"invoice_with_date" AS (
    SELECT
        it."InvoiceID",
        it."InvoiceTotal",
        TO_DATE(inv."InvoiceDate") AS "InvoiceDate"
    FROM "invoice_totals" it
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES inv
      ON it."InvoiceID" = inv."InvoiceID"
),
"quarter_avgs" AS (
    SELECT
        QUARTER("InvoiceDate")                                    AS "Quarter",
        AVG("InvoiceTotal")                                       AS "AvgInvoiceValue"
    FROM "invoice_with_date"
    WHERE YEAR("InvoiceDate") = 2013
    GROUP BY QUARTER("InvoiceDate")
)
SELECT
    MAX("AvgInvoiceValue") - MIN("AvgInvoiceValue") AS "Difference_Max_Min_Average"
FROM "quarter_avgs";