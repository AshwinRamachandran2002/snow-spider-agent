/*  How many customers have orders and invoices that (1) match item-by-item,
    (2) produce the same grand totals for quantity and value and 
    (3) have the same number of orders and invoices?                       */

WITH
/* --------------------------------------------------- */
/* Order lines aggregated per customer & stock item    */
order_lines AS (
    SELECT  o."CustomerID"                                  AS customer_id ,
            ol."StockItemID"                                AS stock_item_id ,
            SUM(ol."Quantity")                              AS order_qty ,
            SUM(ol."Quantity" * ol."UnitPrice")             AS order_value
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"  ol
           JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS" o
             ON ol."OrderID" = o."OrderID"
    GROUP  BY o."CustomerID" , ol."StockItemID"
),

/* Invoice lines aggregated per customer & stock item   */
invoice_lines AS (
    SELECT  i."CustomerID"                                  AS customer_id ,
            il."StockItemID"                                AS stock_item_id ,
            SUM(il."Quantity")                              AS invoice_qty ,
            SUM(il."Quantity" * il."UnitPrice")             AS invoice_value
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
           JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES" i
             ON il."InvoiceID" = i."InvoiceID"
    GROUP  BY i."CustomerID" , il."StockItemID"
),

/* Check item-level equality (quantity & value)          */
line_item_check AS (
    SELECT  COALESCE(o.customer_id , i.customer_id)                 AS customer_id ,
            SUM( COALESCE(o.order_qty   ,0) - COALESCE(i.invoice_qty  ,0) )  AS qty_diff ,
            SUM( COALESCE(o.order_value ,0) - COALESCE(i.invoice_value,0) )  AS value_diff
    FROM   order_lines o
           FULL OUTER JOIN invoice_lines i
             ON  o.customer_id   = i.customer_id
             AND o.stock_item_id = i.stock_item_id
    GROUP  BY COALESCE(o.customer_id , i.customer_id)
),

/* Order-level aggregates                                 */
order_summary AS (
    SELECT  o."CustomerID"                                AS customer_id ,
            COUNT(DISTINCT o."OrderID")                   AS order_cnt ,
            SUM(ol."Quantity" * ol."UnitPrice")           AS order_value
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"      o
           JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES" ol
             ON o."OrderID" = ol."OrderID"
    GROUP  BY o."CustomerID"
),

/* Invoice-level aggregates                               */
invoice_summary AS (
    SELECT  i."CustomerID"                                AS customer_id ,
            COUNT(DISTINCT i."InvoiceID")                 AS invoice_cnt ,
            SUM(il."Quantity" * il."UnitPrice")           AS invoice_value
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     i
           JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
             ON i."InvoiceID" = il."InvoiceID"
    GROUP  BY i."CustomerID"
),

/* Combine all checks                                     */
combined AS (
    SELECT  l.customer_id ,
            os.order_cnt      ,
            isv.invoice_cnt   ,
            os.order_value    ,
            isv.invoice_value ,
            l.qty_diff        ,
            l.value_diff
    FROM   line_item_check  l
           JOIN order_summary   os  ON l.customer_id = os.customer_id
           JOIN invoice_summary isv ON l.customer_id = isv.customer_id
)

/* --------------------------------------------------- */
/* Final answer                                         */
SELECT  COUNT(*) AS "MATCHING_CUSTOMER_COUNT"
FROM    combined
WHERE   qty_diff        = 0
  AND   value_diff      = 0
  AND   order_cnt       = invoice_cnt
  AND   order_value     = invoice_value;