WITH "ORDER_AGG" AS (
    SELECT 
        o."CustomerID",
        COUNT(DISTINCT o."OrderID")                     AS "Order_Count",
        ROUND(SUM(ol."Quantity" * ol."UnitPrice" * (1 + ol."TaxRate" / 100)), 2) AS "Order_Total"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"         o
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"     ol 
          ON o."OrderID" = ol."OrderID"
    GROUP BY o."CustomerID"
),
"INVOICE_AGG" AS (
    SELECT 
        i."CustomerID",
        COUNT(DISTINCT i."InvoiceID")                  AS "Invoice_Count",
        ROUND(SUM(il."ExtendedPrice"), 2)              AS "Invoice_Total"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"       i
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"   il 
          ON i."InvoiceID" = il."InvoiceID"
    GROUP BY i."CustomerID"
),
"MATCHED_CUSTOMERS" AS (
    SELECT 
        o."CustomerID"
    FROM "ORDER_AGG"   o
    JOIN "INVOICE_AGG" i
          ON o."CustomerID" = i."CustomerID"
    WHERE o."Order_Count"   = i."Invoice_Count"
      AND o."Order_Total"   = i."Invoice_Total"
)
SELECT COUNT(*) AS "MatchingCustomerCount"
FROM "MATCHED_CUSTOMERS";