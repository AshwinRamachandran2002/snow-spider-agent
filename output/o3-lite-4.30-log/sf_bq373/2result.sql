WITH customer_monthly AS (
    SELECT
        ih."CustomerID",
        SUBSTR(ih."InvoiceDate", 1, 7) AS "year_month",
        SUM(il."ExtendedPrice")        AS "monthly_spend"
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"     ih
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" il
          ON il."InvoiceID" = ih."InvoiceID"
    WHERE ih."InvoiceDate" LIKE '2014-%'
    GROUP BY ih."CustomerID", SUBSTR(ih."InvoiceDate", 1, 7)
), customer_avg AS (
    SELECT
        "CustomerID",
        AVG("monthly_spend") AS "avg_monthly_spend_2014"
    FROM customer_monthly
    GROUP BY "CustomerID"
)
SELECT
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "avg_monthly_spend_2014"),
        4
    ) AS "median_average_monthly_spending"
FROM customer_avg;