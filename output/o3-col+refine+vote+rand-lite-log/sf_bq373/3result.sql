WITH invoice_2014 AS (
    SELECT  i."CustomerID",
            SUBSTR(i."InvoiceDate", 6, 2)      AS "Month",
            l."ExtendedPrice"
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES      i
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICELINES   l
              ON i."InvoiceID" = l."InvoiceID"
    WHERE   SUBSTR(i."InvoiceDate", 1, 4) = '2014'
),
monthly_totals AS (
    SELECT  "CustomerID",
            "Month",
            SUM("ExtendedPrice")               AS "Monthly_Total"
    FROM    invoice_2014
    GROUP   BY "CustomerID", "Month"
),
customer_avg AS (
    SELECT  "CustomerID",
            AVG("Monthly_Total")               AS "Avg_Monthly_Spend"
    FROM    monthly_totals
    GROUP   BY "CustomerID"
)
SELECT  MEDIAN("Avg_Monthly_Spend")             AS "Median_2014_Avg_Monthly_Spend"
FROM    customer_avg;