WITH per_invoice AS (
    SELECT
        i."InvoiceID",
        /* Map the invoice month to its corresponding quarter */
        CASE
            WHEN TO_NUMBER(SUBSTR(i."InvoiceDate", 6, 2)) BETWEEN 1 AND 3 THEN 'Q1'
            WHEN TO_NUMBER(SUBSTR(i."InvoiceDate", 6, 2)) BETWEEN 4 AND 6 THEN 'Q2'
            WHEN TO_NUMBER(SUBSTR(i."InvoiceDate", 6, 2)) BETWEEN 7 AND 9 THEN 'Q3'
            ELSE 'Q4'
        END                                   AS "Quarter",
        /* Total value of this invoice = Σ(UnitPrice * Quantity) over its lines */
        SUM(il."UnitPrice" * il."Quantity")   AS "Invoice_Total"
    FROM
        WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      i
    JOIN
        WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"  il
          ON il."InvoiceID" = i."InvoiceID"
    /* Restrict to invoices from the year 2013 */
    WHERE SUBSTR(i."InvoiceDate", 1, 4) = '2013'
    GROUP BY i."InvoiceID", "Quarter"
),
quarter_avg AS (
    /* Average invoice value within each quarter */
    SELECT
        "Quarter",
        AVG("Invoice_Total") AS "Avg_Invoice_Value"
    FROM per_invoice
    GROUP BY "Quarter"
)
/* Difference between the maximum and minimum of those quarterly averages */
SELECT
    MAX("Avg_Invoice_Value") - MIN("Avg_Invoice_Value") 
        AS "Diff_Max_Min_Avg_Invoice_Value_2013"
FROM quarter_avg;