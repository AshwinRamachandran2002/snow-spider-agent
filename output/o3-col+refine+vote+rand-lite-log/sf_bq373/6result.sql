WITH invoice_lines_2014 AS (
    SELECT
        i."CustomerID",
        l."ExtendedPrice"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      i
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"  l
           ON i."InvoiceID" = l."InvoiceID"
    WHERE  TO_DATE(i."InvoiceDate") BETWEEN '2014-01-01' AND '2014-12-31'
),
customer_totals AS (
    SELECT
        "CustomerID",
        SUM("ExtendedPrice") AS "Total2014"
    FROM   invoice_lines_2014
    GROUP  BY "CustomerID"
),
customer_avg_month AS (
    SELECT
        "CustomerID",
        "Total2014" / 12 AS "AvgMonthlySpend2014"
    FROM   customer_totals
)
SELECT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "AvgMonthlySpend2014") 
        AS "Median_AvgMonthlySpend2014"
FROM   customer_avg_month;