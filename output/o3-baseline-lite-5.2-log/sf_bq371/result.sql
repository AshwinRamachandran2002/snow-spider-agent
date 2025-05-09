WITH "INVOICE_TOTALS" AS (
    /* 1.  Total value of each invoice = Σ(UnitPrice * Quantity) */
    SELECT
        "InvoiceID",
        SUM("UnitPrice" * "Quantity") AS "Invoice_Total"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICELINES
    GROUP BY "InvoiceID"
),
"INV_WITH_QTR" AS (
    /* 2.  Attach invoice date, keep only 2013, work out the quarter (1–4) */
    SELECT
        it."InvoiceID",
        it."Invoice_Total",
        DATE_PART('quarter', TO_DATE(inv."InvoiceDate")) AS "Quarter"
    FROM "INVOICE_TOTALS" it
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES inv
          ON inv."InvoiceID" = it."InvoiceID"
    WHERE DATE_PART('year', TO_DATE(inv."InvoiceDate")) = 2013
),
"AVG_BY_QTR" AS (
    /* 3.  Average invoice value within each quarter */
    SELECT
        "Quarter",
        AVG("Invoice_Total") AS "Avg_Invoice_Value"
    FROM "INV_WITH_QTR"
    GROUP BY "Quarter"
)
/* 4.  Difference between the maximum and minimum of those quarterly averages */
SELECT
    MAX("Avg_Invoice_Value") - MIN("Avg_Invoice_Value") AS "Diff_Max_Min_Avg_Invoice_Value"
FROM "AVG_BY_QTR";