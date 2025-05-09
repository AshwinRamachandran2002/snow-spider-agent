/*  Customers whose ORDERS and INVOICES
    – match line‑item values (at least one invoice exists for every order),
    – have the same number of orders and invoices,
    – have exactly the same total money value
*/
WITH orders_per_customer AS (
    SELECT
        o."CustomerID",
        COUNT(DISTINCT o."OrderID")                         AS order_cnt,
        /* order line value = qty × unit price × (1+tax%)   */
        SUM(ol."Quantity" * ol."UnitPrice"
            * (1 + ol."TaxRate" / 100.0))                  AS order_val
    FROM  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"        o
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"    ol
           ON ol."OrderID" = o."OrderID"
    /* keep only orders that actually produced invoices    */
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      iv
           ON iv."OrderID" = o."OrderID"
    GROUP BY o."CustomerID"
),
invoices_per_customer AS (
    SELECT
        iv."CustomerID",
        COUNT(DISTINCT iv."InvoiceID")                     AS invoice_cnt,
        /* invoice line value already includes tax          */
        SUM(il."ExtendedPrice")                            AS invoice_val
    FROM  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      iv
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"  il
           ON il."InvoiceID" = iv."InvoiceID"
    GROUP BY iv."CustomerID"
)
SELECT COUNT(*) AS "MATCHING_CUSTOMER_COUNT"
FROM   orders_per_customer  o
JOIN   invoices_per_customer i
       ON i."CustomerID" = o."CustomerID"
WHERE  o.order_cnt  = i.invoice_cnt
  AND  ROUND(o.order_val , 2) = ROUND(i.invoice_val , 2);