WITH monthly AS (
    SELECT
        i."CustomerID",
        TO_CHAR(TO_DATE(i."InvoiceDate"), 'YYYY-MM')       AS "Invoice_Month",
        SUM(il."ExtendedPrice")                            AS "Total_Monthly_Amount"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" il
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     i
      ON il."InvoiceID" = i."InvoiceID"
    WHERE i."InvoiceDate" BETWEEN '2014-01-01' AND '2014-12-31'
    GROUP BY i."CustomerID",
             TO_CHAR(TO_DATE(i."InvoiceDate"), 'YYYY-MM')
),
customer_avg AS (
    SELECT
        "CustomerID",
        AVG("Total_Monthly_Amount") AS "Avg_Monthly_Spend_2014"
    FROM monthly
    GROUP BY "CustomerID"
)
SELECT
    MEDIAN("Avg_Monthly_Spend_2014") AS "Median_Avg_Monthly_Spend_2014"
FROM customer_avg;