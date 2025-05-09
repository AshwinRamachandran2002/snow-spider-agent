WITH order_details AS (   -- per‑order line count and net value (no tax)
    SELECT
        so."CustomerID",
        so."OrderID",
        COUNT(*)                                        AS "order_line_cnt",
        ROUND(SUM(ol."Quantity" * ol."UnitPrice"), 4)   AS "order_value"
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS"     so
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES" ol
      ON ol."OrderID" = so."OrderID"
    GROUP BY so."CustomerID", so."OrderID"
),
invoice_details AS (      -- per‑order invoice line count and net value (no tax, ignore credit notes)
    SELECT
        si."CustomerID",
        si."OrderID",
        COUNT(*)                                        AS "invoice_line_cnt",
        ROUND(SUM(il."Quantity" * il."UnitPrice"), 4)  AS "invoice_value"
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"    si
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" il
      ON il."InvoiceID" = si."InvoiceID"
    WHERE si."IsCreditNote" = 0
    GROUP BY si."CustomerID", si."OrderID"
),
line_matches AS (         -- perfectly matching lines per order
    SELECT
        o."OrderID",
        COUNT(*)                                        AS "matched_line_cnt"
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES"   o
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"     si
      ON si."OrderID" = o."OrderID"
     AND si."IsCreditNote" = 0
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" il
      ON il."InvoiceID"   = si."InvoiceID"
     AND il."StockItemID" = o."StockItemID"
     AND il."Quantity"    = o."Quantity"
     AND il."UnitPrice"   = o."UnitPrice"
    GROUP BY o."OrderID"
),
perfect_orders AS (       -- orders whose invoices match perfectly
    SELECT
        od."CustomerID",
        od."OrderID",
        od."order_value"
    FROM order_details  od
    JOIN invoice_details id ON id."OrderID" = od."OrderID"
    JOIN line_matches   lm ON lm."OrderID" = od."OrderID"
    WHERE   od."order_line_cnt" = id."invoice_line_cnt"
        AND od."order_line_cnt" = lm."matched_line_cnt"
        AND od."order_value"    = id."invoice_value"
),
customer_tot_orders AS (  -- all orders summary per customer (net values)
    SELECT
        "CustomerID",
        COUNT(DISTINCT "OrderID")        AS "tot_order_cnt",
        SUM("order_value")               AS "tot_order_val"
    FROM order_details
    GROUP BY "CustomerID"
),
customer_tot_invoices AS ( -- all invoices summary per customer (net values)
    SELECT
        "CustomerID",
        COUNT(DISTINCT "OrderID")        AS "tot_inv_cnt",
        SUM("invoice_value")             AS "tot_inv_val"
    FROM invoice_details
    GROUP BY "CustomerID"
),
customer_perfect AS (     -- only perfectly matched orders per customer
    SELECT
        "CustomerID",
        COUNT(DISTINCT "OrderID")        AS "perfect_cnt",
        SUM("order_value")               AS "perfect_val"
    FROM perfect_orders
    GROUP BY "CustomerID"
)
SELECT
    COUNT(*) AS matching_customer_count
FROM customer_tot_orders   o
JOIN customer_tot_invoices i ON i."CustomerID" = o."CustomerID"
JOIN customer_perfect      p ON p."CustomerID" = o."CustomerID"
WHERE     o."tot_order_cnt" = i."tot_inv_cnt"
      AND o."tot_order_cnt" = p."perfect_cnt"
      AND o."tot_order_val" = i."tot_inv_val"
      AND o."tot_order_val" = p."perfect_val";