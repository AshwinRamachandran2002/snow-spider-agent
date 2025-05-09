/*  Median of customers' average monthly spending in 2014  */
WITH line_totals AS (          -- monthly totals per customer
    SELECT
        inv."CustomerID",
        DATE_TRUNC('month', TO_DATE(inv."InvoiceDate"))   AS month_start,
        SUM(il."ExtendedPrice" + il."TaxAmount")          AS month_amount
    FROM  "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"      inv
    JOIN  "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES"  il
          ON inv."InvoiceID" = il."InvoiceID"
    WHERE YEAR(TO_DATE(inv."InvoiceDate")) = 2014
    GROUP BY inv."CustomerID",
             DATE_TRUNC('month', TO_DATE(inv."InvoiceDate"))
),
customer_avgs AS (            -- average monthly spend per customer
    SELECT
        "CustomerID",
        SUM(month_amount)/12.0  AS avg_monthly_spend        -- zero for months with no spend
    FROM line_totals
    GROUP BY "CustomerID"
)
SELECT
    MEDIAN(avg_monthly_spend)   AS median_avg_monthly_spend
FROM customer_avgs;