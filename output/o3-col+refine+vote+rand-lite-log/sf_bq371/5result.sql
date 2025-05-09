WITH invoice_totals AS (
    SELECT
        i."InvoiceID",
        CASE
            WHEN SUBSTR(i."InvoiceDate", 6, 2) IN ('01','02','03') THEN 'Q1'
            WHEN SUBSTR(i."InvoiceDate", 6, 2) IN ('04','05','06') THEN 'Q2'
            WHEN SUBSTR(i."InvoiceDate", 6, 2) IN ('07','08','09') THEN 'Q3'
            ELSE 'Q4'
        END AS "Quarter",
        SUM(il."Quantity" * il."UnitPrice") AS "InvoiceTotal"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     i
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
           ON il."InvoiceID" = i."InvoiceID"
    WHERE  i."InvoiceDate" LIKE '2013-%'
    GROUP  BY
           i."InvoiceID",
           CASE
               WHEN SUBSTR(i."InvoiceDate", 6, 2) IN ('01','02','03') THEN 'Q1'
               WHEN SUBSTR(i."InvoiceDate", 6, 2) IN ('04','05','06') THEN 'Q2'
               WHEN SUBSTR(i."InvoiceDate", 6, 2) IN ('07','08','09') THEN 'Q3'
               ELSE 'Q4'
           END
),
quarter_avgs AS (
    SELECT
        "Quarter",
        AVG("InvoiceTotal") AS "AvgInvoiceValue"
    FROM   invoice_totals
    GROUP  BY "Quarter"
)
SELECT
    MAX("AvgInvoiceValue") - MIN("AvgInvoiceValue") AS "DifferenceBetweenMaxAndMinAvg"
FROM   quarter_avgs;