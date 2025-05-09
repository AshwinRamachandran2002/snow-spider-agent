WITH order_totals AS (
    SELECT
        o."CustomerID",
        COUNT(DISTINCT o."OrderID")                                                   AS order_cnt,
        ROUND(SUM(ol."Quantity" * ol."UnitPrice" * (1 + ol."TaxRate" / 100)), 4)      AS order_total
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS"       o
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES"   ol
          ON o."OrderID" = ol."OrderID"
    GROUP BY o."CustomerID"
),
invoice_totals AS (
    SELECT
        i."CustomerID",
        COUNT(DISTINCT i."InvoiceID")                                                 AS invoice_cnt,
        ROUND(SUM(il."Quantity" * il."UnitPrice" * (1 + il."TaxRate" / 100)), 4)      AS invoice_total
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"     i
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" il
          ON i."InvoiceID" = il."InvoiceID"
    GROUP BY i."CustomerID"
)
SELECT COUNT(*) AS matching_customer_count
FROM order_totals  ot
JOIN invoice_totals it
     ON ot."CustomerID" = it."CustomerID"
WHERE ot.order_cnt   = it.invoice_cnt
  AND ot.order_total = it.invoice_total;