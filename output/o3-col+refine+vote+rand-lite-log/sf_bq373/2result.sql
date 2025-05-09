WITH line_amounts_2014 AS (   -- total line value per customer per month in 2014
    SELECT
        i."CustomerID",
        TO_CHAR(TO_DATE(i."InvoiceDate"), 'YYYY-MM') AS "YearMonth",
        SUM(l."ExtendedPrice")                       AS "MonthSpend"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" l
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      i
           ON l."InvoiceID" = i."InvoiceID"
    WHERE  i."InvoiceDate" LIKE '2014-%'
    GROUP  BY i."CustomerID",
              TO_CHAR(TO_DATE(i."InvoiceDate"), 'YYYY-MM')
),
avg_monthly_spend AS (        -- average monthly spend per customer (across the months they purchased)
    SELECT
        "CustomerID",
        AVG("MonthSpend") AS "AvgMonthlySpend"
    FROM line_amounts_2014
    GROUP BY "CustomerID"
)
SELECT
    MEDIAN("AvgMonthlySpend") AS "MedianAvgMonthlySpend_2014"
FROM avg_monthly_spend;