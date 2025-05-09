WITH customer_month_totals AS (
    SELECT
        i."CustomerID",
        SUBSTR(i."InvoiceDate", 1, 7) AS "Month",
        SUM(il."ExtendedPrice") AS "MonthlyTotal"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICELINES il
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES  i
          ON i."InvoiceID" = il."InvoiceID"
    WHERE i."InvoiceDate" LIKE '2014-%'
    GROUP BY i."CustomerID", SUBSTR(i."InvoiceDate", 1, 7)
), customer_avg AS (
    SELECT
        "CustomerID",
        AVG("MonthlyTotal") AS "AvgMonthlySpending"
    FROM customer_month_totals
    GROUP BY "CustomerID"
)
SELECT
    MEDIAN("AvgMonthlySpending") AS "MedianOfAvgMonthlySpend_2014"
FROM customer_avg;