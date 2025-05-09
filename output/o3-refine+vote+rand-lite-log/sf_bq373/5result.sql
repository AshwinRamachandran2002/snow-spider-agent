WITH monthly_totals AS (
    SELECT
        i."CustomerID",
        DATE_TRUNC('month', TO_DATE(i."InvoiceDate"))          AS invoice_month,
        SUM(l."ExtendedPrice")                                 AS month_total
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      i
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"  l
          ON i."InvoiceID" = l."InvoiceID"
    WHERE EXTRACT(year FROM TO_DATE(i."InvoiceDate")) = 2014            -- only year 2014
    GROUP BY
        i."CustomerID",
        DATE_TRUNC('month', TO_DATE(i."InvoiceDate"))
),
customer_averages AS (
    SELECT
        "CustomerID",
        AVG(month_total) AS avg_monthly_spending                         -- average across the months the customer purchased
    FROM monthly_totals
    GROUP BY "CustomerID"
)
SELECT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_monthly_spending)    AS median_avg_monthly_spending
FROM customer_averages;