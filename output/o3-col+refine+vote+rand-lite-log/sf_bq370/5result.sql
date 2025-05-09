/*---------------------------------------------------------------
   Customers whose orders and invoices match perfectly
   – every order has exactly one invoice
   – every order-line (stock, qty, price) exists in the invoice
   – aggregated count and monetary value match, too
----------------------------------------------------------------*/
WITH                                                     -- order-line “signatures”
order_sig AS (
    SELECT ol."OrderID",
           LISTAGG(
               TO_VARCHAR(ol."StockItemID")   || ':' ||
               TO_VARCHAR(ol."Quantity")      || ':' ||
               TO_VARCHAR(ol."UnitPrice"),
               '|'
           ) WITHIN GROUP (ORDER BY ol."StockItemID", ol."Quantity", ol."UnitPrice")  AS "sig"
    FROM   "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES" ol
    GROUP  BY ol."OrderID"
),
invoice_sig AS (
    SELECT il."InvoiceID",
           LISTAGG(
               TO_VARCHAR(il."StockItemID")   || ':' ||
               TO_VARCHAR(il."Quantity")      || ':' ||
               TO_VARCHAR(il."UnitPrice"),
               '|'
           ) WITHIN GROUP (ORDER BY il."StockItemID", il."Quantity", il."UnitPrice")  AS "sig"
    FROM   "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" il
    GROUP  BY il."InvoiceID"
),
---------------------------------------------------------- match each order to its invoice
good_pairs AS (
    SELECT  o."CustomerID",
            o."OrderID",
            i."InvoiceID"
    FROM    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS"  o
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES" i
           ON i."OrderID" = o."OrderID"
    JOIN    order_sig   os  ON os."OrderID"   = o."OrderID"
    JOIN    invoice_sig isg ON isg."InvoiceID" = i."InvoiceID"
    WHERE   os."sig" = isg."sig"                              -- line-items identical
),
---------------------------------------------------------- aggregate orders per customer
orders_agg AS (
    SELECT  o."CustomerID",
            COUNT(DISTINCT o."OrderID")            AS order_cnt,
            SUM(ol."Quantity" * ol."UnitPrice")    AS order_val
    FROM    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS"      o
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES"  ol
           ON ol."OrderID" = o."OrderID"
    GROUP   BY o."CustomerID"
),
---------------------------------------------------------- aggregate invoices per customer
invoices_agg AS (
    SELECT  i."CustomerID",
            COUNT(DISTINCT i."InvoiceID")          AS inv_cnt,
            SUM(il."ExtendedPrice")                AS inv_val
    FROM    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"     i
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" il
           ON il."InvoiceID" = i."InvoiceID"
    GROUP   BY i."CustomerID"
),
---------------------------------------------------------- number of perfectly matched pairs
pair_cnt AS (
    SELECT  "CustomerID",
            COUNT(*)  AS good_pair_cnt
    FROM    good_pairs
    GROUP   BY "CustomerID"
)
---------------------------------------------------------- final answer
SELECT COUNT(*) AS "MatchedCustomerCount"
FROM   orders_agg  o
JOIN   invoices_agg i  ON i."CustomerID" = o."CustomerID"
JOIN   pair_cnt    p   ON p."CustomerID" = o."CustomerID"
WHERE  o.order_cnt = i.inv_cnt                 -- same # orders & invoices
  AND  o.order_cnt = p.good_pair_cnt           -- every pair line-matches
  AND  ABS(o.order_val - i.inv_val) < 0.01;    -- identical total value