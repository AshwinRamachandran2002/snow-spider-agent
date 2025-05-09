WITH "PER_INVOICE" AS (
    SELECT
        i."InvoiceID",
        TRY_TO_DATE(i."InvoiceDate")                        AS "InvoiceDate",
        SUM(l."UnitPrice" * l."Quantity")                  AS "InvoiceValue"
    FROM  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      i
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"  l
          ON i."InvoiceID" = l."InvoiceID"
    WHERE DATE_PART('year', TRY_TO_DATE(i."InvoiceDate")) = 2013
    GROUP BY i."InvoiceID", TRY_TO_DATE(i."InvoiceDate")
),
"QUARTER_AVG" AS (
    SELECT
        DATE_PART('quarter', "InvoiceDate") AS "Quarter",
        AVG("InvoiceValue")                 AS "AvgInvoiceValue"
    FROM "PER_INVOICE"
    GROUP BY DATE_PART('quarter', "InvoiceDate")
)
SELECT
    MAX("AvgInvoiceValue") - MIN("AvgInvoiceValue") AS "Difference_Max_Min_Avg_InvoiceValue"
FROM "QUARTER_AVG";