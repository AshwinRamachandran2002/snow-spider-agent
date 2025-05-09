/* Median of customers’ average monthly spend for the year 2014 */

WITH all_customers AS (       -- every customer that exists
    SELECT "CustomerID"
    FROM   "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_CUSTOMERS"
),

totals_2014 AS (              -- total line amounts per customer for 2014
    SELECT  inv."CustomerID",
            SUM(il."ExtendedPrice") AS total_spend_2014
    FROM    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"      inv
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES"  il
           ON inv."InvoiceID" = il."InvoiceID"
    WHERE   TO_DATE(inv."InvoiceDate") BETWEEN '2014-01-01' AND '2014-12-31'
    GROUP BY inv."CustomerID"
),

avg_monthly AS (              -- average monthly spend (zero if no spend)
    SELECT  c."CustomerID",
            COALESCE(t.total_spend_2014,0) / 12.0  AS avg_monthly_spend
    FROM    all_customers  c
    LEFT JOIN totals_2014  t  ON c."CustomerID" = t."CustomerID"
)

SELECT
    MEDIAN(avg_monthly_spend) AS median_avg_monthly_spend_2014
FROM   avg_monthly;