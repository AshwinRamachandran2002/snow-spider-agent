WITH orders_per_customer AS (      -- value (ex‑tax) of every order
    SELECT
        o."CustomerID",
        o."OrderID",
        SUM(ol."UnitPrice" * ol."Quantity") AS order_value
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_ORDERS       o
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_ORDERLINES   ol
         ON ol."OrderID" = o."OrderID"
    GROUP BY o."CustomerID", o."OrderID"
),
invoices_per_customer AS (        -- value (ex‑tax) of every invoice that relates to an order
    SELECT
        i."CustomerID",
        i."OrderID",
        i."InvoiceID",
        SUM(il."UnitPrice" * il."Quantity") AS invoice_value
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES     i
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICELINES il
         ON il."InvoiceID" = i."InvoiceID"
    WHERE i."OrderID" IS NOT NULL            -- ignore credit notes or stand‑alone invoices
    GROUP BY i."CustomerID", i."OrderID", i."InvoiceID"
),
matched_order_invoice AS (        -- orders whose invoice has exactly the same total value
    SELECT
        o."CustomerID",
        o."OrderID",
        o.order_value,
        i.invoice_value
    FROM orders_per_customer  o
    JOIN invoices_per_customer i
         ON i."CustomerID" = o."CustomerID"
        AND i."OrderID"    = o."OrderID"
    WHERE o.order_value = i.invoice_value    -- line‑item totals match
),
customers_fully_matched AS (      -- customers where every order is perfectly matched by its invoice
    SELECT
        ords."CustomerID"
    FROM (   -- overall order stats
            SELECT "CustomerID",
                   COUNT(DISTINCT "OrderID")        AS total_orders,
                   SUM(order_value)                 AS total_order_value
            FROM orders_per_customer
            GROUP BY "CustomerID"
         ) ords
    JOIN (   -- overall invoice stats
            SELECT "CustomerID",
                   COUNT(DISTINCT "OrderID")        AS total_invoices,
                   SUM(invoice_value)               AS total_invoice_value
            FROM invoices_per_customer
            GROUP BY "CustomerID"
         ) invs
      ON invs."CustomerID" = ords."CustomerID"
    JOIN (   -- only perfectly matched order / invoice pairs
            SELECT "CustomerID",
                   COUNT(DISTINCT "OrderID")        AS matched_orders,
                   SUM(order_value)                 AS matched_value
            FROM matched_order_invoice
            GROUP BY "CustomerID"
         ) matched
      ON matched."CustomerID" = ords."CustomerID"
    WHERE ords.total_orders      = invs.total_invoices      -- equal count of orders & invoices
      AND ords.total_orders      = matched.matched_orders   -- every order perfectly matched
      AND ords.total_order_value = invs.total_invoice_value -- equal total value
      AND ords.total_order_value = matched.matched_value    -- …and that value is from matches
)
SELECT COUNT(*) AS "CUSTOMER_COUNT"
FROM customers_fully_matched;