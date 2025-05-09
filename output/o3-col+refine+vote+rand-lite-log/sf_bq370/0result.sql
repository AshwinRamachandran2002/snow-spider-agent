/*----------------------------------------------------------
  Customers whose Orders and Invoices agree at every level
----------------------------------------------------------*/
WITH
/*-- canonicalised order-lines ---------------------------------------------*/
ord_ln AS (
    SELECT  o."OrderID",
            o."CustomerID",
            ol."StockItemID",
            ol."UnitPrice",
            SUM(ol."Quantity") AS qty          -- un-quoted → becomes QTY
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"      o
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"  ol
              ON o."OrderID" = ol."OrderID"
    GROUP BY o."OrderID",
             o."CustomerID",
             ol."StockItemID",
             ol."UnitPrice"
),
/*-- canonicalised invoice-lines -------------------------------------------*/
inv_ln AS (
    SELECT  i."OrderID",
            i."CustomerID",
            il."StockItemID",
            il."UnitPrice",
            SUM(il."Quantity") AS qty
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     i
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
              ON i."InvoiceID" = il."InvoiceID"
    GROUP BY i."OrderID",
             i."CustomerID",
             il."StockItemID",
             il."UnitPrice"
),
/*-- orders whose line-items DO NOT match any invoice ----------------------*/
mismatch_orders AS (
    SELECT DISTINCT COALESCE(o."OrderID", i."OrderID") AS "OrderID"
    FROM            ord_ln o
    FULL OUTER JOIN inv_ln i
           ON  o."OrderID"     = i."OrderID"
           AND o."StockItemID" = i."StockItemID"
           AND o."UnitPrice"   = i."UnitPrice"
    WHERE  o.qty IS NULL            -- line missing on one side
       OR  i.qty IS NULL
       OR  o.qty <> i.qty           -- quantities differ
),
/*-- customers for whom ALL their orders match at line level --------------*/
perfect_line_cust AS (
    SELECT DISTINCT o."CustomerID"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS" o
    WHERE  NOT EXISTS ( SELECT 1
                        FROM mismatch_orders mo
                        WHERE mo."OrderID" = o."OrderID" )
),
/*-- header-level order / invoice counts -----------------------------------*/
hdr_cnt AS (
    SELECT  c."CustomerID",
            COUNT(DISTINCT o."OrderID")   AS order_cnt,
            COUNT(DISTINCT i."InvoiceID") AS invoice_cnt
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERS"  c
    LEFT JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"   o
           ON c."CustomerID" = o."CustomerID"
    LEFT JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES" i
           ON c."CustomerID" = i."CustomerID"
    GROUP BY c."CustomerID"
),
/*-- aggregated $ values ---------------------------------------------------*/
ord_val AS (
    SELECT  o."CustomerID",
            SUM(ol."Quantity" * ol."UnitPrice") AS order_val
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"      o
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"  ol
             ON o."OrderID" = ol."OrderID"
    GROUP BY o."CustomerID"
),
inv_val AS (
    SELECT  i."CustomerID",
            SUM(il."Quantity" * il."UnitPrice") AS inv_val
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     i
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
             ON i."InvoiceID" = il."InvoiceID"
    GROUP BY i."CustomerID"
)
/*-- final answer ----------------------------------------------------------*/
SELECT COUNT(*) AS "customers_with_perfect_match"
FROM   perfect_line_cust plc
JOIN   hdr_cnt         hc  ON hc."CustomerID"  = plc."CustomerID"
JOIN   ord_val         ov  ON ov."CustomerID"  = plc."CustomerID"
JOIN   inv_val         iv  ON iv."CustomerID"  = plc."CustomerID"
WHERE  hc.order_cnt = hc.invoice_cnt
  AND  ov.order_val = iv.inv_val;