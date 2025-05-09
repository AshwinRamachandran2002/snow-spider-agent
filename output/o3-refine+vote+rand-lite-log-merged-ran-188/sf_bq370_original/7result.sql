/*--------------------------------------------------------------
 How many customers satisfy all of these conditions?

 1. Every order they have is linked to (at least) one invoice.
 2. For every order / invoice pair, the summed line‑item value
    on the order equals the summed line‑item value on the invoice.
 3. After aggregation to customer level:
        • number_of_orders   = number_of_invoices
        • total_order_value  = total_invoice_value
----------------------------------------------------------------*/
WITH
/*‑‑ Sum the value of each order (all its order‑lines) */
ORDERS AS (
    SELECT
        o."OrderID",
        o."CustomerID",
        SUM(ol."Quantity" * ol."UnitPrice")            AS "ORDER_TOTAL"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"       o
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"   ol
           ON  o."OrderID" = ol."OrderID"
    GROUP  BY o."OrderID", o."CustomerID"
),

/*‑‑ Sum the value of every invoice (all its invoice‑lines)  */
INVOICES AS (
    SELECT
        i."InvoiceID",
        i."OrderID",
        i."CustomerID",
        SUM(il."ExtendedPrice")                        AS "INVOICE_TOTAL"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     i
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
           ON  i."InvoiceID" = il."InvoiceID"
    GROUP  BY i."InvoiceID", i."OrderID", i."CustomerID"
),

/*‑‑ Orders whose summed value exactly matches that of (a) linked invoice*/
MATCHED_ORDERS AS (
    SELECT
        o."OrderID",
        o."CustomerID"
    FROM   ORDERS   o
    JOIN   INVOICES i
           ON  o."OrderID"   = i."OrderID"
           AND o."ORDER_TOTAL" = i."INVOICE_TOTAL"      -- line‑level value match
    GROUP  BY o."OrderID", o."CustomerID"
),

/*‑‑ Aggregate counts / totals per customer */
CUST_ORDERS AS (
    SELECT "CustomerID",
           COUNT(*)                       AS "ORDER_CNT",
           SUM("ORDER_TOTAL")             AS "ORDERS_VALUE"
    FROM   ORDERS
    GROUP  BY "CustomerID"
),
CUST_INVOICES AS (
    SELECT "CustomerID",
           COUNT(DISTINCT "InvoiceID")    AS "INVOICE_CNT",
           SUM("INVOICE_TOTAL")           AS "INVOICES_VALUE"
    FROM   INVOICES
    GROUP  BY "CustomerID"
),
CUST_MATCHED AS (
    SELECT "CustomerID",
           COUNT(*)                       AS "MATCHED_CNT"
    FROM   MATCHED_ORDERS
    GROUP  BY "CustomerID"
),

/*‑‑ Bring the three aggregates together */
CUST_COMBINED AS (
    SELECT
        o."CustomerID",
        o."ORDER_CNT",
        i."INVOICE_CNT",
        m."MATCHED_CNT",
        o."ORDERS_VALUE",
        i."INVOICES_VALUE"
    FROM   CUST_ORDERS   o
    JOIN   CUST_INVOICES i  ON i."CustomerID" = o."CustomerID"
    JOIN   CUST_MATCHED  m  ON m."CustomerID" = o."CustomerID"
)

/*‑‑ Customers meeting all requirements */
SELECT COUNT(*) AS "CUSTOMERS_WITH_PERFECT_MATCH"
FROM   CUST_COMBINED
WHERE  "ORDER_CNT"   = "INVOICE_CNT"
  AND  "ORDER_CNT"   = "MATCHED_CNT"          -- every order matched, nothing extra
  AND  "ORDERS_VALUE" = "INVOICES_VALUE";