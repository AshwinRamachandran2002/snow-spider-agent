WITH invoice_totals AS (
    SELECT
        inv."InvoiceID",
        TO_DATE(inv."InvoiceDate")                                   AS "Invoice_Date",
        QUARTER(TO_DATE(inv."InvoiceDate"))                          AS "Quarter",
        SUM(lines."UnitPrice" * lines."Quantity")                    AS "Invoice_Total"
    FROM
        "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"      inv
    JOIN
        "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES"  lines
          ON inv."InvoiceID" = lines."InvoiceID"
    WHERE
        YEAR(TO_DATE(inv."InvoiceDate")) = 2013
    GROUP BY
        inv."InvoiceID",
        TO_DATE(inv."InvoiceDate")
),
quarter_avgs AS (
    SELECT
        "Quarter",
        AVG("Invoice_Total") AS "Avg_Invoice_Value"
    FROM
        invoice_totals
    GROUP BY
        "Quarter"
)
SELECT
    MAX("Avg_Invoice_Value") - MIN("Avg_Invoice_Value") AS "Difference_Max_Min_Avg_Invoice_Value"
FROM
    quarter_avgs;