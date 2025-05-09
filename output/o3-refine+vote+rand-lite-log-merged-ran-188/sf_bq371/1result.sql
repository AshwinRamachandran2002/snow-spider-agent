WITH "INVOICE_TOTALS" AS (   -- total value for each invoice
    SELECT 
        "InvoiceID",
        SUM("UnitPrice" * "Quantity") AS "TOTAL_VALUE"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"
    GROUP BY "InvoiceID"
), 
"INVOICES_2013" AS (         -- attach invoice dates, keep only year 2013
    SELECT 
        it."InvoiceID",
        it."TOTAL_VALUE",
        TO_DATE(inv."InvoiceDate") AS "INVOICE_DATE"
    FROM "INVOICE_TOTALS" it
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES" inv 
          ON it."InvoiceID" = inv."InvoiceID"
    WHERE YEAR(TO_DATE(inv."InvoiceDate")) = 2013
),
"AVG_BY_QTR" AS (            -- average invoice value per quarter
    SELECT 
        QUARTER("INVOICE_DATE") AS "QTR",
        AVG("TOTAL_VALUE")      AS "AVG_VALUE"
    FROM "INVOICES_2013"
    GROUP BY QUARTER("INVOICE_DATE")
)
SELECT 
    MAX("AVG_VALUE") - MIN("AVG_VALUE") AS "DIFFERENCE_MAX_MIN_AVG"
FROM "AVG_BY_QTR";