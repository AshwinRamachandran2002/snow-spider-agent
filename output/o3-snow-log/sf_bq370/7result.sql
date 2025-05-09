WITH 
/* ---------- 1. header-level aggregates per customer ---------- */
"ORDER_STATS" AS (
    SELECT 
        o."CustomerID",
        COUNT(DISTINCT o."OrderID")                       AS "ORDER_CNT",
        SUM(ol."Quantity" * ol."UnitPrice")               AS "ORDER_VAL"
    FROM  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"      o
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"  ol
          ON o."OrderID" = ol."OrderID"
    GROUP BY o."CustomerID"
),
"INVOICE_STATS" AS (
    SELECT 
        i."CustomerID",
        COUNT(DISTINCT i."InvoiceID")                     AS "INV_CNT",
        SUM(il."ExtendedPrice")                           AS "INV_VAL"
    FROM  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      i
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"  il
          ON i."InvoiceID" = il."InvoiceID"
    GROUP BY i."CustomerID"
),

/* ---------- 2. line-level aggregates (per customer & stock item) ---------- */
"ORDER_LINES" AS (
    SELECT 
        o."CustomerID",
        ol."StockItemID",
        SUM(ol."Quantity")                AS "QTY",
        SUM(ol."Quantity"*ol."UnitPrice") AS "VAL"
    FROM  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"     o
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES" ol
          ON o."OrderID" = ol."OrderID"
    GROUP BY o."CustomerID", ol."StockItemID"
),
"INVOICE_LINES" AS (
    SELECT 
        i."CustomerID",
        il."StockItemID",
        SUM(il."Quantity")      AS "QTY",
        SUM(il."ExtendedPrice") AS "VAL"
    FROM  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     i
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
          ON i."InvoiceID" = il."InvoiceID"
    GROUP BY i."CustomerID", il."StockItemID"
),

/* ---------- 3. compare line-level data ---------- */
"LINE_COMPARISON" AS (
    SELECT
        "CustomerID",
        "StockItemID",
        SUM("QTY_DELTA") AS "QTY_DIFF",
        SUM("VAL_DELTA") AS "VAL_DIFF"
    FROM (
        /* orders as +ve */
        SELECT "CustomerID", "StockItemID",  "QTY"  AS "QTY_DELTA",  "VAL"  AS "VAL_DELTA" FROM "ORDER_LINES"
        UNION ALL
        /* invoices as -ve */
        SELECT "CustomerID", "StockItemID", -"QTY", -"VAL"           FROM "INVOICE_LINES"
    ) t
    GROUP BY "CustomerID", "StockItemID"
),
/* customers whose line-items match exactly */
"LINE_MATCH_CUSTOMERS" AS (
    SELECT "CustomerID"
    FROM   "LINE_COMPARISON"
    GROUP  BY "CustomerID"
    HAVING MAX(ABS("QTY_DIFF")) = 0
       AND MAX(ABS("VAL_DIFF")) < 0.0001            -- tolerance for rounding
),

/* ---------- 4. final customers meeting all conditions ---------- */
"FINAL_MATCHES" AS (
    SELECT l."CustomerID"
    FROM   "LINE_MATCH_CUSTOMERS" l
    JOIN   "ORDER_STATS"   o ON o."CustomerID" = l."CustomerID"
    JOIN   "INVOICE_STATS" i ON i."CustomerID" = l."CustomerID"
    WHERE  o."ORDER_CNT"        = i."INV_CNT"
       AND ABS(o."ORDER_VAL" - i."INV_VAL") < 0.0001
)

SELECT COUNT(*) AS "MatchingCustomers"
FROM   "FINAL_MATCHES";