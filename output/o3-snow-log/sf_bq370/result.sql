WITH "ORDER_VALUES" AS (
    SELECT 
        o."CustomerID",
        COUNT(DISTINCT o."OrderID")                                           AS "ORDERS_CNT",
        SUM(ol."UnitPrice" * ol."Quantity" * (1 + ol."TaxRate" / 100))        AS "ORDERS_TOTAL"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"        o
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"    ol
          ON o."OrderID" = ol."OrderID"
    GROUP BY o."CustomerID"
), 
"INVOICE_VALUES" AS (
    SELECT 
        i."CustomerID",
        COUNT(DISTINCT i."InvoiceID")                                         AS "INVOICES_CNT",
        SUM(il."UnitPrice" * il."Quantity" * (1 + il."TaxRate" / 100))        AS "INVOICES_TOTAL"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      i
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"  il
          ON i."InvoiceID" = il."InvoiceID"
    GROUP BY i."CustomerID"
)
SELECT COUNT(*) AS "MATCHING_CUSTOMERS"
FROM (
      SELECT 
          ov."CustomerID",
          ov."ORDERS_CNT",  iv."INVOICES_CNT",
          ov."ORDERS_TOTAL", iv."INVOICES_TOTAL"
      FROM "ORDER_VALUES"   ov
      JOIN "INVOICE_VALUES" iv
            ON ov."CustomerID" = iv."CustomerID"
) j
WHERE j."ORDERS_CNT"   = j."INVOICES_CNT"
  AND  ROUND(j."ORDERS_TOTAL", 2) = ROUND(j."INVOICES_TOTAL", 2);