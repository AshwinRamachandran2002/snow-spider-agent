WITH invoice_lines_2014 AS (
    SELECT
        i."CustomerID",
        DATE_TRUNC('month', TO_DATE(i."InvoiceDate"))   AS month_start,
        il."ExtendedPrice"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      i
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"  il
          ON il."InvoiceID" = i."InvoiceID"
    WHERE TO_DATE(i."InvoiceDate") BETWEEN '2014-01-01' AND '2014-12-31'
),

monthly_totals AS (
    SELECT
        "CustomerID",
        month_start,
        SUM("ExtendedPrice") AS monthly_total
    FROM invoice_lines_2014
    GROUP BY "CustomerID", month_start
),

avg_monthly_per_customer AS (
    SELECT
        "CustomerID",
        AVG(monthly_total) AS avg_monthly_spend          -- average over months that had invoices
    FROM monthly_totals
    GROUP BY "CustomerID"
)

SELECT
    MEDIAN(avg_monthly_spend) AS median_average_monthly_spend
FROM avg_monthly_per_customer;