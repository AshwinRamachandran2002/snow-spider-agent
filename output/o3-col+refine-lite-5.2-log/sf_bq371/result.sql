WITH invoice_totals AS (   -- total value of each 2013 invoice
    SELECT  h."InvoiceID",
            CASE
                WHEN SUBSTR(h."InvoiceDate", 6, 2) IN ('01','02','03') THEN 'Q1'
                WHEN SUBSTR(h."InvoiceDate", 6, 2) IN ('04','05','06') THEN 'Q2'
                WHEN SUBSTR(h."InvoiceDate", 6, 2) IN ('07','08','09') THEN 'Q3'
                ELSE 'Q4'
            END                                         AS "Quarter",
            SUM(l."UnitPrice" * l."Quantity")           AS "Invoice_Total"
    FROM    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" l
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"     h
           ON l."InvoiceID" = h."InvoiceID"
    WHERE   h."InvoiceDate" LIKE '2013%'                -- restrict to year 2013
    GROUP BY h."InvoiceID", "Quarter"
),
quarter_avgs AS (         -- average invoice value per quarter
    SELECT  "Quarter",
            AVG("Invoice_Total") AS "Avg_Invoice_Value"
    FROM    invoice_totals
    GROUP BY "Quarter"
)
SELECT  MAX("Avg_Invoice_Value") - MIN("Avg_Invoice_Value") AS "Difference_Max_Min_Avg"
FROM    quarter_avgs;