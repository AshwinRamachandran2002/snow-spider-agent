WITH invoice_totals AS (
    SELECT
        il."InvoiceID",
        SUM(il."UnitPrice" * il."Quantity") AS "InvoiceTotal",
        CASE
            WHEN TO_NUMBER(SUBSTR(i."InvoiceDate", 6, 2)) BETWEEN 1 AND 3 THEN 'Q1'
            WHEN TO_NUMBER(SUBSTR(i."InvoiceDate", 6, 2)) BETWEEN 4 AND 6 THEN 'Q2'
            WHEN TO_NUMBER(SUBSTR(i."InvoiceDate", 6, 2)) BETWEEN 7 AND 9 THEN 'Q3'
            ELSE 'Q4'
        END AS "Quarter"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      i
      ON il."InvoiceID" = i."InvoiceID"
    WHERE i."InvoiceDate" LIKE '2013-%'
    GROUP BY
        il."InvoiceID",
        CASE
            WHEN TO_NUMBER(SUBSTR(i."InvoiceDate", 6, 2)) BETWEEN 1 AND 3 THEN 'Q1'
            WHEN TO_NUMBER(SUBSTR(i."InvoiceDate", 6, 2)) BETWEEN 4 AND 6 THEN 'Q2'
            WHEN TO_NUMBER(SUBSTR(i."InvoiceDate", 6, 2)) BETWEEN 7 AND 9 THEN 'Q3'
            ELSE 'Q4'
        END
),
quarter_avg AS (
    SELECT
        "Quarter",
        AVG("InvoiceTotal") AS "AvgInvoiceValue"
    FROM invoice_totals
    GROUP BY "Quarter"
)
SELECT
    MAX("AvgInvoiceValue") - MIN("AvgInvoiceValue") AS "DifferenceBetweenMaxAndMin"
FROM quarter_avg;