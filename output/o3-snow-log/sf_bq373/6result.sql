WITH customer_year_totals AS (   -- total 2014 spend for each customer
    SELECT
        I."CustomerID",
        SUM(L."ExtendedPrice") AS year_total
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     I
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" L
          ON I."InvoiceID" = L."InvoiceID"
    WHERE I."InvoiceDate" >= '2014-01-01'
      AND I."InvoiceDate" <  '2015-01-01'          -- entire year 2014
    GROUP BY I."CustomerID"
),
customer_avg_monthly AS (        -- average monthly spend (divide by 12 months)
    SELECT
        "CustomerID",
        year_total / 12 AS avg_monthly_spend
    FROM customer_year_totals
)
SELECT
    MEDIAN(avg_monthly_spend) AS median_avg_monthly_spend
FROM customer_avg_monthly;