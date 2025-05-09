WITH order_line_agg AS (
    SELECT 
        o."CustomerID",
        l."StockItemID",
        SUM(l."Quantity")                    AS "OrderQty",
        SUM(l."Quantity" * l."UnitPrice")    AS "OrderValue"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES" l
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"     o
          ON o."OrderID" = l."OrderID"
    GROUP BY o."CustomerID", l."StockItemID"
),
invoice_line_agg AS (
    SELECT 
        i."CustomerID",
        il."StockItemID",
        SUM(il."Quantity")                   AS "InvoiceQty",
        SUM(il."Quantity" * il."UnitPrice")  AS "InvoiceValue"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     i
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
          ON il."InvoiceID" = i."InvoiceID"
    GROUP BY i."CustomerID", il."StockItemID"
),
line_mismatch AS (
    SELECT 
        COALESCE(o."CustomerID", i."CustomerID") AS "CustomerID"
    FROM order_line_agg  o
    FULL OUTER JOIN invoice_line_agg i
           ON i."CustomerID"  = o."CustomerID"
          AND i."StockItemID" = o."StockItemID"
    WHERE NVL(o."OrderQty",   0) <> NVL(i."InvoiceQty",   0)
       OR NVL(o."OrderValue", 0) <> NVL(i."InvoiceValue", 0)
),
customers_with_line_match AS (
    SELECT DISTINCT "CustomerID"
    FROM (
          SELECT "CustomerID" FROM order_line_agg
          UNION
          SELECT "CustomerID" FROM invoice_line_agg
    )
    WHERE "CustomerID" NOT IN (SELECT "CustomerID" FROM line_mismatch)
),
aggregated_match AS (
    SELECT
        co."CustomerID"
    FROM (
        SELECT 
            o."CustomerID",
            COUNT(DISTINCT l."OrderID")           AS "OrderCnt",
            SUM(l."Quantity" * l."UnitPrice")     AS "OrderTotal"
        FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES" l
        JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"     o
              ON o."OrderID" = l."OrderID"
        GROUP BY o."CustomerID"
    ) co
    JOIN (
        SELECT
            i."CustomerID",
            COUNT(DISTINCT i."InvoiceID")         AS "InvoiceCnt",
            SUM(il."Quantity" * il."UnitPrice")   AS "InvoiceTotal"
        FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     i
        JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
              ON il."InvoiceID" = i."InvoiceID"
        GROUP BY i."CustomerID"
    ) ci
      ON ci."CustomerID" = co."CustomerID"
    WHERE co."OrderCnt"   = ci."InvoiceCnt"
      AND co."OrderTotal" = ci."InvoiceTotal"
)
SELECT COUNT(*) AS "matching_customer_count"
FROM   aggregated_match
WHERE  "CustomerID" IN (SELECT "CustomerID" FROM customers_with_line_match);