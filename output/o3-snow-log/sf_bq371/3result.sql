WITH "INVOICE_TOTALS" AS (
    /* 1.  Total value of each 2013 invoice                    */
    SELECT
        i."InvoiceID",
        TO_DATE(i."InvoiceDate")                AS "InvoiceDate",
        SUM(l."UnitPrice" * l."Quantity")       AS "InvoiceTotal"
    FROM  "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"      i
    JOIN  "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES"  l
          ON i."InvoiceID" = l."InvoiceID"
    WHERE YEAR(TO_DATE(i."InvoiceDate")) = 2013
    GROUP BY i."InvoiceID", TO_DATE(i."InvoiceDate")
), "QUARTER_AVG" AS (
    /* 2.  Average invoice value per calendar quarter          */
    SELECT
        QUARTER("InvoiceDate")                  AS "Quarter",
        AVG("InvoiceTotal")                     AS "AvgInvoiceValue"
    FROM "INVOICE_TOTALS"
    GROUP BY QUARTER("InvoiceDate")
)
SELECT
    MAX("AvgInvoiceValue") - MIN("AvgInvoiceValue") 
        AS "Difference_Max_Min_Average"
FROM "QUARTER_AVG";