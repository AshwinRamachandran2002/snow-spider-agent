WITH invoice_values AS (   -- total value of each 2013 invoice
    SELECT
        i."InvoiceID",
        EXTRACT(QUARTER FROM TO_DATE(i."InvoiceDate"))           AS quarter_num,
        SUM(il."UnitPrice" * il."Quantity")                      AS invoice_value
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES"  il
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"      i
          ON il."InvoiceID" = i."InvoiceID"
    WHERE i."InvoiceDate" >= '2013-01-01'
      AND i."InvoiceDate" <  '2014-01-01'
    GROUP BY i."InvoiceID", quarter_num
),
quarter_avg AS (          -- average invoice value per quarter
    SELECT
        quarter_num,
        AVG(invoice_value) AS avg_value
    FROM invoice_values
    GROUP BY quarter_num
)
SELECT
    MAX(avg_value) - MIN(avg_value)  AS "DIFF_MAX_MIN_AVG_INVOICE_VALUE"
FROM quarter_avg;