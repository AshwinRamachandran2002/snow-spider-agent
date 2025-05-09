WITH invoice_totals AS (            -- total value for each 2013 invoice
    SELECT  il."InvoiceID",
            SUM(il."UnitPrice" * il."Quantity") AS "InvoiceTotal"
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"  il
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"       i
            ON il."InvoiceID" = i."InvoiceID"
    WHERE   i."InvoiceDate" LIKE '2013-%'
    GROUP BY il."InvoiceID"
),
quarter_avgs AS (                   -- average invoice value per 2013 quarter
    SELECT  CASE
                WHEN SUBSTR(i."InvoiceDate", 6, 2) IN ('01','02','03') THEN 'Q1'
                WHEN SUBSTR(i."InvoiceDate", 6, 2) IN ('04','05','06') THEN 'Q2'
                WHEN SUBSTR(i."InvoiceDate", 6, 2) IN ('07','08','09') THEN 'Q3'
                ELSE 'Q4'
            END                                   AS "Quarter",
            AVG(t."InvoiceTotal")                 AS "AvgInvoiceValue"
    FROM    invoice_totals t
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES" i
            ON t."InvoiceID" = i."InvoiceID"
    GROUP BY 1
)
SELECT  MAX("AvgInvoiceValue") - MIN("AvgInvoiceValue") AS "MaxMinDiff"
FROM    quarter_avgs;