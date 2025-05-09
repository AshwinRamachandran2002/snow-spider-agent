WITH month_totals AS (
    /* total spend by customer for every invoice month in calendar-year 2014 */
    SELECT
        i."CustomerID",
        TO_CHAR(TO_DATE(i."InvoiceDate"), 'YYYY-MM')     AS "YearMonth",
        SUM(l."ExtendedPrice")                           AS "MonthSpend"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     i
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" l
          ON l."InvoiceID" = i."InvoiceID"
    WHERE i."InvoiceDate" BETWEEN '2014-01-01' AND '2014-12-31'
    GROUP BY i."CustomerID",
             TO_CHAR(TO_DATE(i."InvoiceDate"), 'YYYY-MM')
),
avg_per_customer AS (
    /* average of those monthly spends for each customer */
    SELECT
        "CustomerID",
        AVG("MonthSpend")                                AS "AvgMonthlySpend"
    FROM month_totals
    GROUP BY "CustomerID"
)
SELECT
    MEDIAN("AvgMonthlySpend")                            AS "MedianAvgMonthlySpend_2014"
FROM avg_per_customer;