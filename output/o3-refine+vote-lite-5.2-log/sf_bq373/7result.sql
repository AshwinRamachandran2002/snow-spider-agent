WITH total_2014 AS (
    SELECT
        i."CustomerID",
        SUM(il."ExtendedPrice") AS total_amount_2014
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES"  il
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"      i
          ON il."InvoiceID" = i."InvoiceID"
    WHERE i."InvoiceDate" >= '2014-01-01'
      AND i."InvoiceDate" <  '2015-01-01'
    GROUP BY i."CustomerID"
)
SELECT
    MEDIAN(avg_monthly_spending) AS median_average_monthly_spending
FROM (
    SELECT
        c."CustomerID",
        COALESCE(t.total_amount_2014, 0) / 12 AS avg_monthly_spending
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_CUSTOMERS" c
    LEFT JOIN total_2014 t
           ON c."CustomerID" = t."CustomerID"
);