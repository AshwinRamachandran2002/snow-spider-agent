WITH order_invoice_pairs AS (          -- every Invoice that refers back to an Order
    SELECT  si."OrderID",
            si."InvoiceID",
            si."CustomerID"
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES  si
    WHERE   si."OrderID" IS NOT NULL
),

/* ---- 1.  Line-item comparison, Order ↔ Invoice ---------------------------- */
order_lines AS (
    SELECT  p."OrderID",
            ol."StockItemID",
            SUM(ol."Quantity")   AS qty_order
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_ORDERLINES  ol
    JOIN    order_invoice_pairs                                         p
           ON p."OrderID" = ol."OrderID"
    GROUP BY p."OrderID", ol."StockItemID"
),
invoice_lines AS (
    SELECT  p."OrderID",
            il."StockItemID",
            SUM(il."Quantity")   AS qty_invoice
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICELINES  il
    JOIN    order_invoice_pairs                                          p
           ON p."InvoiceID" = il."InvoiceID"
    GROUP BY p."OrderID", il."StockItemID"
),
line_mismatches AS (                   -- any difference in StockItem / Quantity
    SELECT  COALESCE(o."OrderID", i."OrderID") AS "OrderID"
    FROM    order_lines  o
    FULL OUTER JOIN invoice_lines i
           ON  o."OrderID"     = i."OrderID"
           AND o."StockItemID" = i."StockItemID"
    WHERE   COALESCE(o.qty_order,0) <> COALESCE(i.qty_invoice,0)
),
mismatch_customers AS (                -- customers that have *any* bad order
    SELECT DISTINCT p."CustomerID"
    FROM   line_mismatches     m
    JOIN   order_invoice_pairs p  ON p."OrderID" = m."OrderID"
),

/* ---- 2.  Aggregate counts & money values ---------------------------------- */
orders_tot AS (
    SELECT  p."CustomerID",
            COUNT(DISTINCT p."OrderID")                       AS orders_cnt,
            SUM(ol."Quantity" * ol."UnitPrice")              AS orders_val
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_ORDERLINES  ol
    JOIN    order_invoice_pairs                                         p
           ON p."OrderID" = ol."OrderID"
    GROUP BY p."CustomerID"
),
invoices_tot AS (
    SELECT  p."CustomerID",
            COUNT(DISTINCT p."InvoiceID")                     AS invoices_cnt,
            SUM(il."ExtendedPrice")                          AS invoices_val
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICELINES  il
    JOIN    order_invoice_pairs                                          p
           ON p."InvoiceID" = il."InvoiceID"
    GROUP BY p."CustomerID"
),

/* ---- 3.  Customers that satisfy *all* requirements ------------------------ */
good_customers AS (
    SELECT  o."CustomerID"
    FROM    orders_tot  o
    JOIN    invoices_tot i
           ON i."CustomerID" = o."CustomerID"
    WHERE   o.orders_cnt  = i.invoices_cnt
      AND   ROUND(o.orders_val , 2) = ROUND(i.invoices_val , 2)
      AND   o."CustomerID" NOT IN (SELECT mc."CustomerID" FROM mismatch_customers mc)
)

SELECT COUNT(*) AS "Matched_Customer_Count"
FROM   good_customers;