WITH "invoice_totals" AS (            -- total value for every invoice
  SELECT
    l."InvoiceID",
    SUM(l."Quantity" * l."UnitPrice") AS "InvoiceTotal"
  FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" l
  GROUP BY l."InvoiceID"
),
"invoice_2013" AS (                   -- keep only 2013 invoices and tag quarter
  SELECT
    i."InvoiceID",
    t."InvoiceTotal",
    CASE
      WHEN SUBSTR(i."InvoiceDate", 6, 2) IN ('01','02','03') THEN 'Q1'
      WHEN SUBSTR(i."InvoiceDate", 6, 2) IN ('04','05','06') THEN 'Q2'
      WHEN SUBSTR(i."InvoiceDate", 6, 2) IN ('07','08','09') THEN 'Q3'
      ELSE 'Q4'
    END AS "Quarter"
  FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      i
  JOIN "invoice_totals"                                                  t
        ON i."InvoiceID" = t."InvoiceID"
  WHERE i."InvoiceDate" LIKE '2013-%'
),
"avg_per_quarter" AS (                -- average invoice value by quarter
  SELECT
    "Quarter",
    AVG("InvoiceTotal") AS "AvgInvoiceValue"
  FROM "invoice_2013"
  GROUP BY "Quarter"
)
SELECT                                   -- difference between max & min averages
  MAX("AvgInvoiceValue") - MIN("AvgInvoiceValue") AS "DifferenceMaxMinAvgInvoiceValue"
FROM "avg_per_quarter";