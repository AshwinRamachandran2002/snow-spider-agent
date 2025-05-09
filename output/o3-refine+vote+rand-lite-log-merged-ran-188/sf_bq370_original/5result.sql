WITH orders_by_customer AS (
    SELECT
        O."CustomerID",
        COUNT(DISTINCT O."OrderID")                                      AS order_cnt,
        SUM(OL."UnitPrice" * OL."Quantity")                              AS order_total
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"        O
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"    OL
          ON O."OrderID" = OL."OrderID"
    GROUP BY O."CustomerID"
),
invoices_by_customer AS (
    SELECT
        I."CustomerID",
        COUNT(DISTINCT I."InvoiceID")                                    AS invoice_cnt,
        SUM(IL."ExtendedPrice")                                          AS invoice_total
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      I
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"  IL
          ON I."InvoiceID" = IL."InvoiceID"
    GROUP BY I."CustomerID"
),
matched_customers AS (
    SELECT
        o."CustomerID"
    FROM orders_by_customer  o
    JOIN invoices_by_customer i
          ON o."CustomerID" = i."CustomerID"
    WHERE o.order_cnt   = i.invoice_cnt
      AND o.order_total = i.invoice_total
)
SELECT COUNT(*) AS "CUSTOMERS_MATCHING"
FROM   matched_customers;