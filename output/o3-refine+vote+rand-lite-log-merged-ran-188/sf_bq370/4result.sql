/* Customers whose order-lines and invoice-lines are a perfect 1-to-1 match
   (line level, order/invoice counts, and aggregated monetary value)           */

WITH /*--------- detailed lines for orders and invoices ----------------------*/
     order_lines AS (
        SELECT  o."CustomerID",
                o."OrderID",
                ol."StockItemID",
                ol."Quantity",
                ol."UnitPrice"
        FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_ORDERS      o
        JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_ORDERLINES  ol
               ON ol."OrderID" = o."OrderID"
     ),
     invoice_lines AS (
        SELECT  i."CustomerID",
                i."OrderID",                       -- order that generated invoice
                il."StockItemID",
                il."Quantity",
                il."UnitPrice"
        FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES     i
        JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICELINES il
               ON il."InvoiceID" = i."InvoiceID"
     ),

/*--------- any line‐level differences between the two sets ------------------*/
     line_mismatches AS (
        /* lines present on orders but absent / different on invoices */
        SELECT * FROM order_lines
        EXCEPT
        SELECT * FROM invoice_lines

        UNION ALL

        /* lines present on invoices but absent / different on orders */
        SELECT * FROM invoice_lines
        EXCEPT
        SELECT * FROM order_lines
     ),

/*--------- customers with ZERO line mismatches ------------------------------*/
     line_matched_customers AS (
        SELECT DISTINCT "CustomerID"
        FROM   order_lines
        WHERE  "CustomerID" NOT IN (SELECT DISTINCT "CustomerID"
                                    FROM line_mismatches)
     ),

/*--------- compare counts and total values for those customers --------------*/
     orders_per_cust AS (
        SELECT  "CustomerID",
                COUNT(DISTINCT "OrderID")                            AS order_cnt,
                SUM("Quantity" * "UnitPrice")                       AS order_val
        FROM    order_lines
        GROUP BY "CustomerID"
     ),
     invoices_per_cust AS (
        SELECT  "CustomerID",
                COUNT(DISTINCT "OrderID")                            AS invoice_cnt,
                SUM("Quantity" * "UnitPrice")                       AS invoice_val
        FROM    invoice_lines
        GROUP BY "CustomerID"
     ),

     fully_matched_customers AS (
        SELECT c."CustomerID"
        FROM   line_matched_customers            c
        JOIN   orders_per_cust    o ON o."CustomerID" = c."CustomerID"
        JOIN   invoices_per_cust  i ON i."CustomerID" = c."CustomerID"
        WHERE  o.order_cnt  = i.invoice_cnt
          AND  o.order_val  = i.invoice_val
     )

/*------------------ final answer --------------------------------------------*/
SELECT COUNT(*) AS "Matching_Customer_Total"
FROM   fully_matched_customers;