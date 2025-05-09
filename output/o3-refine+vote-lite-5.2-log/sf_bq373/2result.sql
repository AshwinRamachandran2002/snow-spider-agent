WITH invoice_lines_2014 AS (
    SELECT
        inv."CustomerID",
        il."ExtendedPrice"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      inv
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"  il
          ON inv."InvoiceID" = il."InvoiceID"
    WHERE EXTRACT(year FROM TO_DATE(inv."InvoiceDate")) = 2014
),
customer_totals AS (
    SELECT
        "CustomerID",
        SUM("ExtendedPrice") AS total_2014_spend
    FROM invoice_lines_2014
    GROUP BY "CustomerID"
),
customer_avg_monthly AS (
    SELECT
        "CustomerID",
        total_2014_spend / 12 AS avg_monthly_spend
    FROM customer_totals
)
SELECT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_monthly_spend) 
        AS median_of_avg_monthly_spend
FROM customer_avg_monthly;