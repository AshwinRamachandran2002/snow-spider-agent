/*  How many customers satisfy ALL of these conditions?
    1)  Every stock-item/quantity/value that appears on their sales orders
        is present on their sales invoices – and vice-versa
        (i.e. line-item level match after aggregation per item).
    2)  The total number of orders equals the total number of invoices.
    3)  The grand total value of all order lines equals the grand total
        value of all invoice lines.
*/
WITH
/*-- 1. aggregate order and invoice rows to customer-item level ‑-*/
orders_item AS (
    SELECT
        so."CustomerID",
        sol."StockItemID",
        SUM(sol."Quantity")                         AS order_qty,
        SUM(sol."Quantity" * sol."UnitPrice")       AS order_val
    FROM   "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS"      so
    JOIN   "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES"  sol
           ON so."OrderID" = sol."OrderID"
    GROUP  BY so."CustomerID", sol."StockItemID"
),
invoices_item AS (
    SELECT
        si."CustomerID",
        sil."StockItemID",
        SUM(sil."Quantity")                         AS inv_qty,
        SUM(sil."ExtendedPrice")                    AS inv_val
    FROM   "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"     si
    JOIN   "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" sil
           ON si."InvoiceID" = sil."InvoiceID"
    GROUP  BY si."CustomerID", sil."StockItemID"
),
/*-- 2. find any customer/item rows that do NOT match between orders & invoices ‑-*/
item_diffs AS (
    SELECT
        COALESCE(o."CustomerID", i."CustomerID")        AS "CustomerID",
        COALESCE(o."StockItemID", i."StockItemID")      AS "StockItemID"
    FROM   orders_item  o
    FULL   OUTER JOIN  invoices_item i
           ON  o."CustomerID"  = i."CustomerID"
           AND o."StockItemID" = i."StockItemID"
    WHERE  NVL(o.order_qty ,0) <> NVL(i.inv_qty ,0)
        OR NVL(o.order_val ,0) <> NVL(i.inv_val ,0)
),
/*-- 3. customers whose line-items MATCH perfectly ‑-*/
line_matched_customers AS (
    SELECT DISTINCT o."CustomerID"
    FROM   orders_item o
    WHERE  o."CustomerID" NOT IN (SELECT "CustomerID" FROM item_diffs)
),
/*-- 4. aggregate counts & totals per customer from orders and invoices ‑-*/
order_totals AS (
    SELECT
        so."CustomerID",
        COUNT(DISTINCT so."OrderID")                         AS order_cnt,
        SUM(sol."Quantity" * sol."UnitPrice")               AS order_val
    FROM   "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS"     so
    JOIN   "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES" sol
           ON so."OrderID" = sol."OrderID"
    GROUP  BY so."CustomerID"
),
invoice_totals AS (
    SELECT
        si."CustomerID",
        COUNT(DISTINCT si."InvoiceID")                       AS inv_cnt,
        SUM(sil."ExtendedPrice")                             AS inv_val
    FROM   "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"    si
    JOIN   "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" sil
           ON si."InvoiceID" = sil."InvoiceID"
    GROUP  BY si."CustomerID"
),
/*-- 5. keep customers that also match on counts & grand totals ‑-*/
fully_matched_customers AS (
    SELECT  lm."CustomerID"
    FROM    line_matched_customers          lm
    JOIN    order_totals                    o  ON o."CustomerID" = lm."CustomerID"
    JOIN    invoice_totals                  i  ON i."CustomerID" = lm."CustomerID"
    WHERE   o.order_cnt = i.inv_cnt
      AND   o.order_val = i.inv_val
)
SELECT COUNT(*) AS matching_customers
FROM   fully_matched_customers;