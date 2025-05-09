WITH
/*-----------------------------------------------------------
1.  Flatten order‑ and invoice‑lines so they can be compared
-----------------------------------------------------------*/
order_lines AS (
    SELECT 
        so."OrderID",
        so."CustomerID",
        ol."StockItemID",
        ol."Quantity",
        ol."UnitPrice"
    FROM  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_ORDERS       so
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_ORDERLINES   ol
          ON so."OrderID" = ol."OrderID"
),
invoice_lines AS (
    SELECT 
        si."OrderID",
        si."CustomerID",
        il."StockItemID",
        il."Quantity",
        il."UnitPrice"
    FROM  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES     si
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICELINES il
          ON si."InvoiceID" = il."InvoiceID"
),

/*-----------------------------------------------------------
2.  Aggregate by order & stock‑item (line‑item granularity)
-----------------------------------------------------------*/
orders_by_item AS (
    SELECT
        "OrderID",
        "CustomerID",
        "StockItemID",
        SUM("Quantity")                   AS ord_qty,
        SUM("Quantity" * "UnitPrice")     AS ord_val
    FROM order_lines
    GROUP BY "OrderID","CustomerID","StockItemID"
),
invoices_by_item AS (
    SELECT
        "OrderID",
        "CustomerID",
        "StockItemID",
        SUM("Quantity")                   AS inv_qty,
        SUM("Quantity" * "UnitPrice")     AS inv_val
    FROM invoice_lines
    GROUP BY "OrderID","CustomerID","StockItemID"
),

/*-----------------------------------------------------------
3.  Keep only orders whose line‑items match invoices 1‑to‑1
-----------------------------------------------------------*/
matched_orders AS (
    SELECT
        COALESCE(o."OrderID",  i."OrderID")     AS "OrderID",
        COALESCE(o."CustomerID",i."CustomerID") AS "CustomerID"
    FROM orders_by_item  o
    FULL JOIN invoices_by_item i
           ON  o."OrderID"     = i."OrderID"
           AND o."StockItemID" = i."StockItemID"
    GROUP BY
        COALESCE(o."OrderID",  i."OrderID"),
        COALESCE(o."CustomerID",i."CustomerID")
    HAVING
        SUM(ABS(COALESCE(o.ord_qty ,0) - COALESCE(i.inv_qty ,0))) = 0
    AND SUM(ABS(COALESCE(o.ord_val,0) - COALESCE(i.inv_val,0))) = 0
),

/*-----------------------------------------------------------
4.  Total value per order (orders vs. invoices)
-----------------------------------------------------------*/
order_totals AS (
    SELECT
        m."CustomerID",
        m."OrderID",
        SUM(ol."Quantity" * ol."UnitPrice") AS order_value
    FROM matched_orders m
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_ORDERLINES ol
      ON m."OrderID" = ol."OrderID"
    GROUP BY m."CustomerID", m."OrderID"
),
invoice_totals AS (
    SELECT
        m."CustomerID",
        m."OrderID",
        SUM(il."ExtendedPrice")             AS invoice_value
    FROM matched_orders m
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES     si
      ON m."OrderID" = si."OrderID"
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICELINES il
      ON si."InvoiceID" = il."InvoiceID"
    GROUP BY m."CustomerID", m."OrderID"
),

/*-----------------------------------------------------------
5.  Compare counts & totals at customer level
-----------------------------------------------------------*/
customer_comparison AS (
    SELECT
        ot."CustomerID",
        COUNT(DISTINCT ot."OrderID") AS orders_cnt,
        SUM(ot.order_value)          AS orders_total,
        COUNT(DISTINCT it."OrderID") AS invoices_cnt,
        SUM(it.invoice_value)        AS invoices_total
    FROM order_totals  ot
    JOIN invoice_totals it
      ON ot."OrderID" = it."OrderID"
    GROUP BY ot."CustomerID"
)

/*-----------------------------------------------------------
6.  How many customers satisfy all conditions?
-----------------------------------------------------------*/
SELECT COUNT(*) AS "MATCHING_CUSTOMERS"
FROM   customer_comparison
WHERE  orders_cnt   = invoices_cnt
  AND  orders_total = invoices_total;