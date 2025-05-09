/*---------------------------------------------------------------
  How many customers have SALES_ORDERS whose every line-item
  is perfectly reproduced on the corresponding SALES_INVOICES?
  A customer qualifies when, for every OrderID raised by that
  customer, there exists exactly one Invoice whose line-count
  and extended value (Qty * UnitPrice) match **order‐by‐order**.
  We then make sure the customer’s total number of orders equals
  the total number of invoices and that the summed values match.
----------------------------------------------------------------*/
WITH  orders AS (          -- one row per Order (value & line-count)
        SELECT  so."CustomerID",
                so."OrderID",
                COUNT(*)                                AS "ord_lines",
                SUM(ol."Quantity"*ol."UnitPrice")       AS "ord_value"
        FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"      so
        JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"  ol
               ON  so."OrderID" = ol."OrderID"
        GROUP  BY so."CustomerID", so."OrderID"
),
      invoices AS (        -- one row per Invoice, rolled up to its OrderID
        SELECT  si."CustomerID",
                si."OrderID",                          -- link back to order
                COUNT(*)                                AS "inv_lines",
                SUM(il."Quantity"*il."UnitPrice")       AS "inv_value"
        FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     si
        JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
               ON  si."InvoiceID" = il."InvoiceID"
        GROUP  BY si."CustomerID", si."OrderID"
),
/* Orders whose matching invoice has identical line-item count
   and monetary value (order-level perfection). */
      order_match AS (
        SELECT  o."CustomerID",
                o."OrderID"
        FROM    orders   o
        JOIN    invoices i
               ON  o."CustomerID" = i."CustomerID"
               AND o."OrderID"    = i."OrderID"
               AND o."ord_lines"  = i."inv_lines"
               AND o."ord_value"  = i."inv_value"
),
/* Count how many of each customer’s orders satisfied the test. */
      per_cust_good AS (
        SELECT  "CustomerID",
                COUNT(*) AS "good_orders"
        FROM    order_match
        GROUP  BY "CustomerID"
),
/* Totals of orders and invoices per customer (for final equality test). */
      per_cust_ord AS (
        SELECT  "CustomerID", COUNT(*) AS "total_orders"
        FROM    orders
        GROUP  BY "CustomerID"
),
      per_cust_inv AS (
        SELECT  "CustomerID", COUNT(*) AS "total_invoices"
        FROM    invoices
        GROUP  BY "CustomerID"
)
/* A customer qualifies only if:
     • every one of their orders had a perfect invoice (good_orders = total_orders)
     • the counts of orders and invoices are identical
     • (the value condition is already enforced at order level) */
SELECT COUNT(*) AS "PerfectMatchCustomerCount"
FROM   per_cust_good   g
JOIN   per_cust_ord    o  ON g."CustomerID" = o."CustomerID"
JOIN   per_cust_inv    v  ON g."CustomerID" = v."CustomerID"
WHERE  g."good_orders"    = o."total_orders"
  AND  o."total_orders"   = v."total_invoices";