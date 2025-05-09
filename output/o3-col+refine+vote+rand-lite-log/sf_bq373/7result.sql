WITH monthly_totals AS (
    SELECT
        i."CustomerID",
        TO_CHAR(TO_DATE(i."InvoiceDate"), 'YYYY-MM')           AS "Invoice_Month",
        SUM(l."ExtendedPrice")                                 AS "Monthly_Total"
    FROM  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"  l
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      i
          ON l."InvoiceID" = i."InvoiceID"
    WHERE TO_DATE(i."InvoiceDate") BETWEEN '2014-01-01' AND '2014-12-31'
    GROUP BY
        i."CustomerID",
        TO_CHAR(TO_DATE(i."InvoiceDate"), 'YYYY-MM')
),
average_per_customer AS (
    SELECT
        "CustomerID",
        AVG("Monthly_Total") AS "Avg_Monthly_Spend_2014"
    FROM monthly_totals
    GROUP BY "CustomerID"
)
SELECT
    MEDIAN("Avg_Monthly_Spend_2014") AS "Median_Avg_Monthly_Spend_2014"
FROM average_per_customer;