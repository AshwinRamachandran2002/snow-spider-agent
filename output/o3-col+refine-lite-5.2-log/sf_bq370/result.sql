WITH ord AS (  -- aggregated order information per customer (line‑item based)
    SELECT  o."CustomerID",
            COUNT(DISTINCT o."OrderID")                        AS "order_cnt",
            SUM(ol."Quantity" * ol."UnitPrice")               AS "order_value"
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"       o
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"   ol
            ON o."OrderID" = ol."OrderID"
    GROUP BY o."CustomerID"
),
inv AS (  -- aggregated invoice information per customer (line‑item based)
    SELECT  i."CustomerID",
            COUNT(DISTINCT i."InvoiceID")                      AS "invoice_cnt",
            SUM(il."Quantity" * il."UnitPrice")               AS "invoice_value"
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     i
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
            ON i."InvoiceID" = il."InvoiceID"
    GROUP BY i."CustomerID"
)
SELECT COUNT(*) AS "matching_customers"
FROM   ord
JOIN   inv USING ("CustomerID")
WHERE  ord."order_cnt"     = inv."invoice_cnt"
  AND  ord."order_value"   = inv."invoice_value";