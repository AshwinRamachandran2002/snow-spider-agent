WITH invoice_totals AS (
    SELECT
        inv."InvoiceID",
        inv."InvoiceDate",
        SUM(lin."Quantity" * lin."UnitPrice") AS invoice_total_value
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES     inv
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICELINES lin
          ON inv."InvoiceID" = lin."InvoiceID"
    WHERE inv."InvoiceDate" BETWEEN '2013-01-01' AND '2013-12-31'
    GROUP BY inv."InvoiceID", inv."InvoiceDate"
),
quarter_avgs AS (
    SELECT
        CASE 
            WHEN SUBSTR("InvoiceDate", 6, 2) IN ('01','02','03') THEN 'Q1'
            WHEN SUBSTR("InvoiceDate", 6, 2) IN ('04','05','06') THEN 'Q2'
            WHEN SUBSTR("InvoiceDate", 6, 2) IN ('07','08','09') THEN 'Q3'
            ELSE 'Q4'
        END AS quarter,
        AVG(invoice_total_value) AS avg_invoice_value
    FROM invoice_totals
    GROUP BY quarter
)
SELECT
    MAX(avg_invoice_value) - MIN(avg_invoice_value) AS difference_between_max_and_min_quarterly_averages_2013
FROM quarter_avgs;