WITH month_tot AS (
    SELECT 
        i."CustomerID",
        EXTRACT(MONTH FROM TO_DATE(i."InvoiceDate")) AS "month_num",
        SUM(l."ExtendedPrice")                      AS "month_total"
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"     i
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" l
      ON l."InvoiceID" = i."InvoiceID"
    WHERE i."InvoiceDate" BETWEEN '2014-01-01' AND '2014-12-31'
    GROUP BY i."CustomerID",
             EXTRACT(MONTH FROM TO_DATE(i."InvoiceDate"))
), 
avg_per_cust AS (
    SELECT
        "CustomerID",
        SUM("month_total") / 12 AS "avg_monthly_spend"
    FROM month_tot
    GROUP BY "CustomerID"
)
SELECT 
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "avg_monthly_spend"),
        4
    ) AS median_average_monthly_spending
FROM avg_per_cust;