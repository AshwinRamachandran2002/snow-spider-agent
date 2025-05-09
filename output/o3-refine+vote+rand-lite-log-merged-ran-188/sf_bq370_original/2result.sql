/*  How many customers have orders whose line‑items are an exact, 1‑for‑1
    match with their related invoice line‑items and, after aggregation,
    show the same number of orders/invoices and the same total value?  */

WITH
/* -------- order‑side detail (one row per customer‑order‑item) -------- */
ORD AS (
    SELECT
        o."CustomerID",
        o."OrderID",
        ol."StockItemID",
        SUM(ol."Quantity")                    AS ord_qty,
        SUM(ol."Quantity" * ol."UnitPrice")   AS ord_val
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"      o
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"  ol
           ON o."OrderID" = ol."OrderID"
    GROUP  BY o."CustomerID", o."OrderID", ol."StockItemID"
),

/* -------- invoice‑side detail (one row per customer‑order‑item) ------ */
INV AS (
    SELECT
        i."CustomerID",
        i."OrderID",
        il."StockItemID",
        SUM(il."Quantity")          AS inv_qty,
        SUM(il."ExtendedPrice")     AS inv_val
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     i
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
           ON i."InvoiceID" = il."InvoiceID"
    GROUP  BY i."CustomerID", i."OrderID", il."StockItemID"
),

/* -------- line‑item comparison -------------------------------------- */
FULL_COMPARE AS (
    SELECT
        COALESCE(ord."CustomerID", inv."CustomerID")     AS customer_id,
        COALESCE(ord."OrderID"    , inv."OrderID"    )   AS order_id,
        COALESCE(ord."StockItemID", inv."StockItemID")   AS item_id,
        COALESCE(ord.ord_qty ,0) AS ord_qty,  COALESCE(inv.inv_qty ,0) AS inv_qty,
        COALESCE(ord.ord_val,0) AS ord_val,  COALESCE(inv.inv_val,0) AS inv_val
    FROM  ORD ord
    FULL  JOIN INV inv
           ON  ord."CustomerID" = inv."CustomerID"
           AND ord."OrderID"    = inv."OrderID"
           AND ord."StockItemID"= inv."StockItemID"
),

/*  Customers with ANY mismatch at the line‑item level */
MISMATCH AS (
    SELECT DISTINCT customer_id
    FROM   FULL_COMPARE
    WHERE  ord_qty <> inv_qty
       OR  ord_val <> inv_val
),

/* -------- aggregated order facts per customer ----------------------- */
ORD_AGG AS (
    SELECT
        o."CustomerID",
        COUNT(DISTINCT o."OrderID")                    AS ord_cnt,
        SUM(ol."Quantity" * ol."UnitPrice")            AS ord_total
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"     o
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES" ol
           ON o."OrderID" = ol."OrderID"
    GROUP  BY o."CustomerID"
),

/* -------- aggregated invoice facts per customer --------------------- */
INV_AGG AS (
    SELECT
        i."CustomerID",
        COUNT(DISTINCT i."InvoiceID")                  AS inv_cnt,
        SUM(il."ExtendedPrice")                        AS inv_total
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     i
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
           ON i."InvoiceID" = il."InvoiceID"
    GROUP  BY i."CustomerID"
)

/* -------- final answer ---------------------------------------------- */
SELECT COUNT(*) AS customers_with_perfect_match
FROM   ORD_AGG  oa
JOIN   INV_AGG  ia  ON oa."CustomerID" = ia."CustomerID"
LEFT  JOIN MISMATCH m ON m.customer_id   = oa."CustomerID"
WHERE  m.customer_id IS NULL                   -- no line‑item mismatches
  AND  oa.ord_cnt   = ia.inv_cnt               -- same count of orders/invoices
  AND  oa.ord_total = ia.inv_total;            -- same total value