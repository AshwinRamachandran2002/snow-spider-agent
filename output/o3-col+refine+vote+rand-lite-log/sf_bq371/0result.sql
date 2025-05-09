WITH invoice_totals AS (
    /* 1.  total value for every 2013 invoice */
    SELECT
        l."InvoiceID",
        SUM(l."Quantity" * l."UnitPrice") AS "InvoiceTotalValue"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICELINES  l
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES      i
          ON l."InvoiceID" = i."InvoiceID"
    WHERE i."InvoiceDate" LIKE '2013-%'        -- limit to calendar-year 2013
    GROUP BY l."InvoiceID"
),
quarterly_avg AS (
    /* 2.  average invoice value per calendar quarter */
    SELECT
        CASE
            WHEN SUBSTR(i."InvoiceDate", 6, 2) IN ('01','02','03') THEN 'Q1'
            WHEN SUBSTR(i."InvoiceDate", 6, 2) IN ('04','05','06') THEN 'Q2'
            WHEN SUBSTR(i."InvoiceDate", 6, 2) IN ('07','08','09') THEN 'Q3'
            ELSE 'Q4'
        END                               AS "Quarter",
        AVG(t."InvoiceTotalValue")        AS "AvgInvoiceValue"
    FROM invoice_totals                             t
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES  i
          ON t."InvoiceID" = i."InvoiceID"
    GROUP BY 1
)
SELECT
    ROUND( MAX("AvgInvoiceValue") - MIN("AvgInvoiceValue"), 4 ) AS "Difference"
FROM quarterly_avg;