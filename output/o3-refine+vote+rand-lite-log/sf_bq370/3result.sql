WITH "ORDER_AGG" AS (          -- totals built from order‑lines
    SELECT
        o."CustomerID",
        COUNT(DISTINCT o."OrderID")                                         AS "ORDER_CNT",
        SUM(ol."Quantity" * ol."UnitPrice" * (1 + ol."TaxRate" / 100))      AS "ORDER_VAL"
    FROM  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"      o
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"  ol
          ON ol."OrderID" = o."OrderID"
    GROUP BY o."CustomerID"
),
"INVOICE_AGG" AS (             -- totals built from invoice‑lines
    SELECT
        i."CustomerID",
        COUNT(DISTINCT i."InvoiceID")                                       AS "INV_CNT",
        SUM(il."ExtendedPrice")                                             AS "INV_VAL"
    FROM  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     i
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
          ON il."InvoiceID" = i."InvoiceID"
    GROUP BY i."CustomerID"
),
"MATCHED_CUSTOMERS" AS (       -- customers whose orders and invoices align
    SELECT
        o."CustomerID"
    FROM  "ORDER_AGG"   o
    JOIN  "INVOICE_AGG" i  ON i."CustomerID" = o."CustomerID"
    WHERE o."ORDER_CNT" = i."INV_CNT"
      AND ABS(o."ORDER_VAL" - i."INV_VAL") < 0.0001   -- equality tolerance
)
SELECT COUNT(*) AS "CUSTOMER_COUNT"
FROM   "MATCHED_CUSTOMERS";