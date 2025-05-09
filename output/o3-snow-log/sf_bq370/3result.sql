WITH
/* 1.  Order-line level detail per customer */
order_line_detail AS (
    SELECT  o."CustomerID",
            ol."StockItemID",
            ol."Quantity",
            ol."UnitPrice",
            COUNT(*)                                  AS "OrderLineCount"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"       o
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"   ol
           ON o."OrderID" = ol."OrderID"
    GROUP  BY o."CustomerID", ol."StockItemID", ol."Quantity", ol."UnitPrice"
),

/* 2.  Invoice-line level detail per customer */
invoice_line_detail AS (
    SELECT  i."CustomerID",
            il."StockItemID",
            il."Quantity",
            il."UnitPrice",
            COUNT(*)                                  AS "InvoiceLineCount"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     i
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
           ON i."InvoiceID" = il."InvoiceID"
    GROUP  BY i."CustomerID", il."StockItemID", il."Quantity", il."UnitPrice"
),

/* 3.  Compare order-lines and invoice-lines one-for-one */
line_comparison AS (
    SELECT  COALESCE(o."CustomerID",  i."CustomerID")     AS "CustomerID",
            COALESCE(o."StockItemID", i."StockItemID")    AS "StockItemID",
            COALESCE(o."Quantity",    i."Quantity")       AS "Quantity",
            COALESCE(o."UnitPrice",   i."UnitPrice")      AS "UnitPrice",
            NVL(o."OrderLineCount",   0)                  AS "OrderLineCount",
            NVL(i."InvoiceLineCount", 0)                  AS "InvoiceLineCount"
    FROM   order_line_detail  o
    FULL   OUTER JOIN invoice_line_detail i
           ON  o."CustomerID"  = i."CustomerID"
           AND o."StockItemID" = i."StockItemID"
           AND o."Quantity"    = i."Quantity"
           AND o."UnitPrice"   = i."UnitPrice"
),

/* 4.  Customers whose order-lines EXACTLY match invoice-lines */
customers_with_perfect_line_match AS (
    SELECT "CustomerID"
    FROM   line_comparison
    GROUP  BY "CustomerID"
    HAVING MAX(CASE WHEN "OrderLineCount" <> "InvoiceLineCount" THEN 1 ELSE 0 END) = 0
),

/* 5.  Aggregate order data per customer */
order_agg AS (
    SELECT  o."CustomerID",
            COUNT(DISTINCT o."OrderID")                       AS "OrderCount",
            SUM(ol."Quantity" * ol."UnitPrice")              AS "OrderTotalValue"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"     o
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES" ol
           ON o."OrderID" = ol."OrderID"
    GROUP  BY o."CustomerID"
),

/* 6.  Aggregate invoice data per customer */
invoice_agg AS (
    SELECT  i."CustomerID",
            COUNT(DISTINCT i."InvoiceID")                     AS "InvoiceCount",
            SUM(il."Quantity" * il."UnitPrice")              AS "InvoiceTotalValue"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     i
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
           ON i."InvoiceID" = il."InvoiceID"
    GROUP  BY i."CustomerID"
),

/* 7.  Customers whose order & invoice counts and totals are equal */
customer_level_match AS (
    SELECT  o."CustomerID"
    FROM    order_agg  o
    JOIN    invoice_agg i
           ON o."CustomerID" = i."CustomerID"
    WHERE   o."OrderCount"      = i."InvoiceCount"
      AND   o."OrderTotalValue" = i."InvoiceTotalValue"
)

/* 8.  Final answer: how many customers satisfy ALL conditions */
SELECT COUNT(*) AS "MATCHING_CUSTOMER_COUNT"
FROM  (
        SELECT DISTINCT c."CustomerID"
        FROM   customers_with_perfect_line_match c
        JOIN   customer_level_match            m
               ON c."CustomerID" = m."CustomerID"
      );