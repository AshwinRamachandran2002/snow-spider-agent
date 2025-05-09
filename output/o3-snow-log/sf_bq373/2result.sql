WITH invoice_lines_2014 AS (   -- all invoice lines that belong to invoices dated in 2014
    SELECT
        i."CustomerID"                     AS customer_id,
        TO_DATE(i."InvoiceDate")           AS invoice_date,
        l."ExtendedPrice"                  AS line_amount
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"    i
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" l
          ON i."InvoiceID" = l."InvoiceID"
    WHERE YEAR(TO_DATE(i."InvoiceDate")) = 2014
),
customer_month_totals AS (      -- spend per customer-month
    SELECT
        customer_id,
        DATE_TRUNC('month', invoice_date) AS month_start,
        SUM(line_amount)                  AS month_total
    FROM invoice_lines_2014
    GROUP BY customer_id, DATE_TRUNC('month', invoice_date)
),
customer_avg_monthly AS (       -- average monthly spend per customer
    SELECT
        customer_id,
        AVG(month_total)         AS avg_monthly_spending
    FROM customer_month_totals
    GROUP BY customer_id
)
SELECT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_monthly_spending)
        AS median_avg_monthly_spending
FROM customer_avg_monthly;