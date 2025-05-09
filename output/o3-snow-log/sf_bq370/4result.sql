WITH
/* aggregate all order lines per customer */
ORDERS_AGG AS (
    SELECT
        o."CustomerID",
        COUNT(DISTINCT o."OrderID")                                   AS ORDER_CNT,
        SUM(ol."Quantity" * ol."UnitPrice")                           AS ORDER_TOTAL
    FROM  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"      o
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"  ol
          ON o."OrderID" = ol."OrderID"
    GROUP BY o."CustomerID"
),
/* aggregate all invoice lines per customer */
INVOICES_AGG AS (
    SELECT
        i."CustomerID",
        COUNT(DISTINCT i."InvoiceID")                                  AS INV_CNT,
        SUM(il."Quantity" * il."UnitPrice")                            AS INV_TOTAL
    FROM  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     i
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
          ON i."InvoiceID" = il."InvoiceID"
    GROUP BY i."CustomerID"
)
/* count customers whose orders and invoices match in count and total value */
SELECT COUNT(*) AS MATCHING_CUSTOMER_COUNT
FROM (
    SELECT o."CustomerID"
    FROM   ORDERS_AGG  o
    JOIN   INVOICES_AGG i
           ON o."CustomerID" = i."CustomerID"
    WHERE  o.ORDER_CNT   = i.INV_CNT
      AND  ROUND(o.ORDER_TOTAL , 2) = ROUND(i.INV_TOTAL , 2)
) AS matched;