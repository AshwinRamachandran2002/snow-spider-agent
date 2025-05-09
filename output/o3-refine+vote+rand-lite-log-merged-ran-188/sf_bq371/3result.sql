WITH "INVOICE_TOTALS" AS (
    SELECT
        i."InvoiceID",
        EXTRACT(QUARTER FROM TO_DATE(i."InvoiceDate", 'YYYY-MM-DD'))     AS "Quarter",
        SUM(l."UnitPrice" * l."Quantity")                               AS "TotalValue"
    FROM
        "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"       i
        JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" l
              ON i."InvoiceID" = l."InvoiceID"
    WHERE
        i."InvoiceDate" BETWEEN '2013-01-01' AND '2013-12-31'
    GROUP BY
        i."InvoiceID",
        "Quarter"
),
"QUARTER_AVG" AS (
    SELECT
        "Quarter",
        AVG("TotalValue") AS "AvgInvoiceValue"
    FROM
        "INVOICE_TOTALS"
    GROUP BY
        "Quarter"
)
SELECT
    MAX("AvgInvoiceValue") - MIN("AvgInvoiceValue") AS "Difference_Max_Min_Average"
FROM
    "QUARTER_AVG";