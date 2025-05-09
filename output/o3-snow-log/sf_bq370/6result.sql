/*  Customers whose orders and invoices                  */
/*  1.  match **per line-item** (same total quantity     */
/*      per StockItemID),                                */
/*  2.  have the same number of orders and invoices,     */
/*  3.  have identical aggregated order / invoice value. */

WITH  /* total quantity of each stock item ordered by every customer */
ORDER_LINES AS (
    SELECT  so."CustomerID",
            sol."StockItemID",
            SUM(sol."Quantity")          AS "Order_Qty"
    FROM    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS"      so
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES"  sol
           ON so."OrderID" = sol."OrderID"
    GROUP BY so."CustomerID", sol."StockItemID"
),

/* total quantity of each stock item invoiced to every customer */
INVOICE_LINES AS (
    SELECT  si."CustomerID",
            sil."StockItemID",
            SUM(sil."Quantity")          AS "Inv_Qty"
    FROM    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"     si
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" sil
           ON si."InvoiceID" = sil."InvoiceID"
    GROUP BY si."CustomerID", sil."StockItemID"
),

/* customers where an order/invoice line does NOT match */
LINE_MISMATCH AS (
    SELECT  COALESCE(ol."CustomerID", il."CustomerID") AS "CustomerID"
    FROM    ORDER_LINES  ol
    FULL JOIN INVOICE_LINES il
           ON  ol."CustomerID"  = il."CustomerID"
           AND ol."StockItemID" = il."StockItemID"
    WHERE   COALESCE(ol."Order_Qty",0) <> COALESCE(il."Inv_Qty",0)
),

/* aggregated order facts per customer */
ORDER_AGG AS (
    SELECT  so."CustomerID",
            COUNT(DISTINCT so."OrderID")                 AS "Order_Cnt",
            SUM(sol."UnitPrice"*sol."Quantity")          AS "Order_Val"
    FROM    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS"      so
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES"  sol
           ON so."OrderID" = sol."OrderID"
    GROUP BY so."CustomerID"
),

/* aggregated invoice facts per customer */
INVOICE_AGG AS (
    SELECT  si."CustomerID",
            COUNT(DISTINCT si."InvoiceID")               AS "Inv_Cnt",
            SUM(sil."UnitPrice"*sil."Quantity")          AS "Inv_Val"
    FROM    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"     si
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" sil
           ON si."InvoiceID" = sil."InvoiceID"
    GROUP BY si."CustomerID"
),

/* customers satisfying all three conditions */
MATCHING_CUSTOMERS AS (
    SELECT  o."CustomerID"
    FROM    ORDER_AGG   o
    JOIN    INVOICE_AGG i
           ON o."CustomerID" = i."CustomerID"
    WHERE   o."Order_Cnt" = i."Inv_Cnt"
      AND   o."Order_Val" = i."Inv_Val"
      AND   o."CustomerID" NOT IN (SELECT "CustomerID" FROM LINE_MISMATCH)
)

SELECT  COUNT(*) AS "Matching_Customers"
FROM    MATCHING_CUSTOMERS;