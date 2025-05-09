WITH monthly_spend AS (
    SELECT 
        i."CustomerID",
        TO_CHAR(TO_DATE(i."InvoiceDate"), 'YYYY-MM')               AS "yyyymm",
        SUM(il."ExtendedPrice")                                    AS "monthly_spend"
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" il
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"      i
          ON il."InvoiceID" = i."InvoiceID"
    WHERE TO_DATE(i."InvoiceDate") BETWEEN '2014-01-01' AND '2014-12-31'
    GROUP BY i."CustomerID", TO_CHAR(TO_DATE(i."InvoiceDate"), 'YYYY-MM')
),
avg_spend AS (
    SELECT
        "CustomerID",
        AVG("monthly_spend") AS "avg_monthly_spend_2014"
    FROM monthly_spend
    GROUP BY "CustomerID"
)
SELECT 
    MEDIAN("avg_monthly_spend_2014") OVER () AS "median_avg_monthly_spend_2014"
FROM avg_spend
LIMIT 1;