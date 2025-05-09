WITH invoice_lines_2014 AS (   -- every line that belongs to a 2014-dated invoice
    SELECT
        h."CustomerID",
        SUBSTRING(h."InvoiceDate", 1, 7)  AS "YearMonth",   -- YYYY-MM
        l."ExtendedPrice"
    FROM  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"  l
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      h
          ON l."InvoiceID" = h."InvoiceID"
    WHERE SUBSTRING(h."InvoiceDate", 1, 4) = '2014'
),

customer_month_totals AS (      -- total spend per customer per month
    SELECT
        "CustomerID",
        "YearMonth",
        SUM("ExtendedPrice")    AS "MonthTotal"
    FROM   invoice_lines_2014
    GROUP  BY "CustomerID", "YearMonth"
),

customer_avg_monthly AS (       -- average monthly spend for each customer
    SELECT
        "CustomerID",
        AVG("MonthTotal")       AS "AvgMonthlySpend"
    FROM   customer_month_totals
    GROUP  BY "CustomerID"
)

SELECT
    MEDIAN("AvgMonthlySpend")   AS "Median_AvgMonthlySpend_2014"
FROM   customer_avg_monthly;