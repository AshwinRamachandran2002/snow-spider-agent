WITH invoice_totals AS (
    /* 1.  Get every 2013 invoice’s total value               */
    /*     (= sum of UnitPrice * Quantity across its lines)    */
    SELECT  inv."InvoiceID",
            TO_DATE(inv."InvoiceDate", 'YYYY-MM-DD')        AS "Invoice_Date",
            SUM(ln."UnitPrice" * ln."Quantity")             AS "Invoice_Total"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES      inv
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICELINES  ln
           ON inv."InvoiceID" = ln."InvoiceID"
    WHERE  YEAR(TO_DATE(inv."InvoiceDate", 'YYYY-MM-DD')) = 2013
    GROUP  BY inv."InvoiceID", TO_DATE(inv."InvoiceDate", 'YYYY-MM-DD')
),
quarter_avg AS (
    /* 2.  Average invoice value per quarter */
    SELECT  QUARTER("Invoice_Date")                  AS "Quarter",
            AVG("Invoice_Total")                     AS "Avg_Invoice_Value"
    FROM    invoice_totals
    GROUP   BY QUARTER("Invoice_Date")
)
/* 3.  Difference between the maximum and minimum quarterly averages */
SELECT  MAX("Avg_Invoice_Value") - MIN("Avg_Invoice_Value")  AS "Difference_Max_Min_Avg"
FROM    quarter_avg;