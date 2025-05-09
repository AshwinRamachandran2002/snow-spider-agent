WITH 
/* 1. aggregate every customer’s orders down to a single record */
"ORDER_AGG" AS (
    SELECT 
        o."CustomerID",
        COUNT(DISTINCT o."OrderID")              AS "Order_Cnt",
        SUM(ol."Quantity" * ol."UnitPrice")      AS "Order_Val"
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS"        o
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES"    ol
          ON o."OrderID" = ol."OrderID"
    GROUP BY o."CustomerID"
),

/* 2. aggregate every customer’s invoices down to a single record */
"INVOICE_AGG" AS (
    SELECT 
        i."CustomerID",
        COUNT(DISTINCT i."InvoiceID")            AS "Inv_Cnt",
        SUM(il."ExtendedPrice")                  AS "Inv_Val"
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"      i
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES"  il
          ON i."InvoiceID" = il."InvoiceID"
    GROUP BY i."CustomerID"
),

/* 3. keep only customers where order & invoice aggregates match */
"MATCHED" AS (
    SELECT 
        o."CustomerID"
    FROM "ORDER_AGG"  o
    JOIN "INVOICE_AGG" i
          ON o."CustomerID" = i."CustomerID"
    WHERE  o."Order_Cnt" = i."Inv_Cnt"
      AND  ABS(o."Order_Val" - i."Inv_Val") < 0.0001   -- tolerance for rounding
)

/* 4. answer: how many such customers exist? */
SELECT COUNT(*) AS "MatchingCustomerCount"
FROM "MATCHED";