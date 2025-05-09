WITH month_totals AS (
    SELECT 
        i."CustomerID",
        SUBSTR(i."InvoiceDate", 1, 7)      AS "yyyy_mm",
        SUM(l."ExtendedPrice")             AS "month_total"
    FROM 
        "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" l
    JOIN 
        "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES" i
        ON l."InvoiceID" = i."InvoiceID"
    WHERE 
        i."InvoiceDate" LIKE '2014-%'          -- only invoices from 2014
    GROUP BY 
        i."CustomerID",
        SUBSTR(i."InvoiceDate", 1, 7)
), avg_spend_per_customer AS (
    SELECT
        "CustomerID",
        AVG("month_total") AS "avg_monthly_spend"
    FROM 
        month_totals
    GROUP BY 
        "CustomerID"
)
SELECT 
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "avg_monthly_spend"),
        4
    ) AS "median_average_monthly_spending"
FROM 
    avg_spend_per_customer;