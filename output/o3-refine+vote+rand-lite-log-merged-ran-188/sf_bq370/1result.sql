/*  How many customers meet ALL of the following?
      1.  Their order–lines and invoice–lines match exactly for every StockItem
         (same items, same total quantity, same total value).
      2.  The aggregated total value of all order-lines equals the aggregated
         total value of all invoice-lines (tolerance 0.0001 to absorb rounding).
      3.  The number of distinct orders equals the number of distinct invoices.
*/
WITH
/* Aggregate every customer’s order-lines */
order_item AS (
    SELECT  o."CustomerID",
            ol."StockItemID",
            SUM(ol."Quantity")                           AS order_qty,
            SUM(ol."Quantity" * ol."UnitPrice")          AS order_val
    FROM    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS"      o
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES"  ol
           ON ol."OrderID" = o."OrderID"
    GROUP BY o."CustomerID", ol."StockItemID"
),
/* Aggregate every customer’s invoice-lines */
invoice_item AS (
    SELECT  i."CustomerID",
            il."StockItemID",
            SUM(il."Quantity")                           AS invoice_qty,
            SUM(il."ExtendedPrice")                      AS invoice_val
    FROM    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"     i
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" il
           ON il."InvoiceID" = i."InvoiceID"
    GROUP BY i."CustomerID", il."StockItemID"
),
/* Compare order vs. invoice at the line-item level */
line_diff AS (
    SELECT  COALESCE(oi."CustomerID", ii."CustomerID")      AS "CustomerID",
            COALESCE(oi."StockItemID", ii."StockItemID")    AS "StockItemID",
            COALESCE(oi.order_qty ,0)  - COALESCE(ii.invoice_qty ,0) AS qty_diff,
            COALESCE(oi.order_val ,0)  - COALESCE(ii.invoice_val ,0) AS val_diff
    FROM    order_item  oi
    FULL OUTER JOIN invoice_item ii
           ON  oi."CustomerID"  = ii."CustomerID"
           AND oi."StockItemID" = ii."StockItemID"
),
/* Keep customers whose line-items match perfectly */
cust_item_match AS (
    SELECT  "CustomerID"
    FROM    line_diff
    GROUP BY "CustomerID"
    HAVING  SUM(ABS(qty_diff)) = 0
        AND SUM(ABS(val_diff)) < 0.0001
),
/* Order / invoice counts and total values per customer */
order_cnt  AS (
    SELECT "CustomerID", COUNT(DISTINCT "OrderID")   AS ord_cnt
    FROM   "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS"
    GROUP BY "CustomerID"
),
invoice_cnt AS (
    SELECT "CustomerID", COUNT(DISTINCT "InvoiceID") AS inv_cnt
    FROM   "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"
    GROUP BY "CustomerID"
),
order_val AS (
    SELECT "CustomerID", SUM(order_val) AS ord_val
    FROM   order_item
    GROUP BY "CustomerID"
),
invoice_val AS (
    SELECT "CustomerID", SUM(invoice_val) AS inv_val
    FROM   invoice_item
    GROUP BY "CustomerID"
)
/* Final answer: number of customers satisfying all conditions */
SELECT  COUNT(*) AS "MATCHING_CUSTOMER_COUNT"
FROM    cust_item_match           cim
JOIN    order_cnt                 oc  USING ("CustomerID")
JOIN    invoice_cnt               ic  USING ("CustomerID")
JOIN    order_val                 ov  USING ("CustomerID")
JOIN    invoice_val               iv  USING ("CustomerID")
WHERE   oc.ord_cnt = ic.inv_cnt
  AND   ABS(ov.ord_val - iv.inv_val) < 0.0001;