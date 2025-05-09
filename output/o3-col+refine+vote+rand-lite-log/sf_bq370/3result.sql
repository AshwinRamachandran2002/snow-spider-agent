/* Count customers whose Orders and Invoices
   – match line-by-line on (Order, StockItem, Qty, Value)
   – have equal counts and identical total values            */

WITH
orders AS (   -- aggregated order figures
    SELECT  so."CustomerID",
            COUNT(DISTINCT so."OrderID")                 AS order_cnt,
            SUM(ol."Quantity" * ol."UnitPrice")         AS order_val
    FROM    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS"      so
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES"  ol
           ON ol."OrderID" = so."OrderID"
    GROUP BY so."CustomerID"
),
invoices AS ( -- aggregated invoice figures
    SELECT  si."CustomerID",
            COUNT(DISTINCT si."InvoiceID")               AS inv_cnt,
            SUM(il."ExtendedPrice")                      AS inv_val
    FROM    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"     si
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" il
           ON il."InvoiceID" = si."InvoiceID"
    GROUP BY si."CustomerID"
),
order_lines AS (   -- per-customer, per-order, per-item totals from orders
    SELECT  o."CustomerID",
            ol."OrderID",
            ol."StockItemID",
            SUM(ol."Quantity")                   AS ord_qty,
            SUM(ol."Quantity"*ol."UnitPrice")    AS ord_val
    FROM    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS"      o
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES"  ol
           ON ol."OrderID" = o."OrderID"
    GROUP BY o."CustomerID", ol."OrderID", ol."StockItemID"
),
invoice_lines AS ( -- per-customer, per-order, per-item totals from invoices
    SELECT  i."CustomerID",
            i."OrderID",
            il."StockItemID",
            SUM(il."Quantity")                  AS inv_qty,
            SUM(il."ExtendedPrice")             AS inv_val
    FROM    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"     i
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" il
           ON il."InvoiceID" = i."InvoiceID"
    GROUP BY i."CustomerID", i."OrderID", il."StockItemID"
),
line_diff AS (      -- detect any per-line discrepancies
    SELECT  COALESCE(ol."CustomerID",  il."CustomerID")   AS "CustomerID",
            COALESCE(ol."OrderID",     il."OrderID")      AS "OrderID",
            COALESCE(ol."StockItemID", il."StockItemID")  AS "StockItemID",
            NVL(ol.ord_qty, 0)                            AS ord_qty,
            NVL(il.inv_qty, 0)                            AS inv_qty,
            NVL(ol.ord_val, 0)                            AS ord_val,
            NVL(il.inv_val, 0)                            AS inv_val
    FROM order_lines  ol
    FULL JOIN invoice_lines il
           ON  ol."CustomerID" = il."CustomerID"
           AND ol."OrderID"    = il."OrderID"
           AND ol."StockItemID"= il."StockItemID"
),
customer_line_status AS ( -- 0 = perfect match, >0 = discrepancy
    SELECT  "CustomerID",
            SUM( CASE WHEN ord_qty = inv_qty
                        AND ord_val = inv_val
                      THEN 0 ELSE 1 END ) AS mismatch_lines
    FROM    line_diff
    GROUP BY "CustomerID"
),
valid_customers AS (       -- customers satisfying all conditions
    SELECT  o."CustomerID"
    FROM    orders  o
    JOIN    invoices i               ON i."CustomerID" = o."CustomerID"
    JOIN    customer_line_status cls ON cls."CustomerID" = o."CustomerID"
    WHERE   o.order_cnt  = i.inv_cnt
      AND   o.order_val  = i.inv_val
      AND   cls.mismatch_lines = 0
)
SELECT COUNT(*) AS "Matching_Customers"
FROM   valid_customers;