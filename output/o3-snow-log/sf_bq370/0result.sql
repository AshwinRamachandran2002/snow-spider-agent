WITH
/* --------- 1. order-lines that do NOT have a matching invoice-line --------- */
unmatched_order_lines AS (
    SELECT ord."CustomerID"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"   ol
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"       ord ON ord."OrderID" = ol."OrderID"
    LEFT  JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES" inv ON inv."OrderID" = ord."OrderID"
    LEFT  JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
           ON  il."InvoiceID"  = inv."InvoiceID"
           AND il."StockItemID"= ol."StockItemID"
           AND il."Quantity"   = ol."Quantity"
           AND il."UnitPrice"  = ol."UnitPrice"
    WHERE  il."InvoiceLineID" IS NULL                      -- no match found
    GROUP  BY ord."CustomerID"
),
/* --------- 2. invoice-lines that do NOT have a matching order-line --------- */
unmatched_invoice_lines AS (
    SELECT inv."CustomerID"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     inv ON inv."InvoiceID" = il."InvoiceID"
    LEFT  JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES" ol
           ON  ol."OrderID"    = inv."OrderID"
           AND ol."StockItemID"= il."StockItemID"
           AND ol."Quantity"   = il."Quantity"
           AND ol."UnitPrice"  = il."UnitPrice"
    WHERE  ol."OrderLineID" IS NULL                       -- no match found
    GROUP  BY inv."CustomerID"
),
/* --------- 3. aggregate values for ORDERS --------- */
order_agg AS (
    SELECT ord."CustomerID",
           COUNT(DISTINCT ord."OrderID")          AS order_cnt,
           SUM(ol."Quantity"*ol."UnitPrice")      AS order_total
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"       ord
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"   ol
           ON ol."OrderID" = ord."OrderID"
    GROUP  BY ord."CustomerID"
),
/* --------- 4. aggregate values for INVOICES --------- */
invoice_agg AS (
    SELECT inv."CustomerID",
           COUNT(DISTINCT inv."InvoiceID")        AS invoice_cnt,
           SUM(il."Quantity"*il."UnitPrice")      AS invoice_total
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     inv
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
           ON il."InvoiceID" = inv."InvoiceID"
    GROUP  BY inv."CustomerID"
),
/* --------- 5. customers whose orders & invoices match line-by-line and in aggregate --------- */
eligible_customers AS (
    SELECT o."CustomerID"
    FROM   order_agg  o
    JOIN   invoice_agg i  ON i."CustomerID" = o."CustomerID"
    LEFT  JOIN unmatched_order_lines  uo ON uo."CustomerID" = o."CustomerID"
    LEFT  JOIN unmatched_invoice_lines ui ON ui."CustomerID" = o."CustomerID"
    WHERE  uo."CustomerID" IS NULL                  -- every order line has a twin invoice line
      AND  ui."CustomerID" IS NULL                  -- every invoice line has a twin order line
      AND  o.order_cnt   = i.invoice_cnt            -- same number of orders & invoices
      AND  ROUND(o.order_total ,2) = ROUND(i.invoice_total ,2)  -- identical total value
)
/* --------- 6. final answer --------- */
SELECT COUNT(*) AS "CUSTOMER_COUNT"
FROM   eligible_customers;