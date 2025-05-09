WITH "ORDER_SUMMARY" AS (
    SELECT
        o."CustomerID"                      AS "CustomerID",
        COUNT(DISTINCT o."OrderID")         AS "Order_Count",
        COUNT(*)                            AS "Order_Line_Count",
        SUM(ol."Quantity" * ol."UnitPrice") AS "Order_Total_Value"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"       o
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"   ol
           ON o."OrderID" = ol."OrderID"
    GROUP  BY o."CustomerID"
),
"INVOICE_SUMMARY" AS (
    SELECT
        i."CustomerID"                     AS "CustomerID",
        COUNT(DISTINCT i."InvoiceID")      AS "Invoice_Count",
        COUNT(*)                           AS "Invoice_Line_Count",
        SUM(il."ExtendedPrice")            AS "Invoice_Total_Value"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     i
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
           ON i."InvoiceID" = il."InvoiceID"
    GROUP  BY i."CustomerID"
),
"COMBINED" AS (
    SELECT
        o."CustomerID",
        o."Order_Count",
        s."Invoice_Count",
        o."Order_Line_Count",
        s."Invoice_Line_Count",
        o."Order_Total_Value",
        s."Invoice_Total_Value"
    FROM   "ORDER_SUMMARY"   o
    JOIN   "INVOICE_SUMMARY" s
           ON o."CustomerID" = s."CustomerID"
)
SELECT COUNT(*) AS "Matching_Customers"
FROM   "COMBINED"
WHERE  "Order_Count"        = "Invoice_Count"
  AND  "Order_Line_Count"   = "Invoice_Line_Count"
  AND  "Order_Total_Value"  = "Invoice_Total_Value";