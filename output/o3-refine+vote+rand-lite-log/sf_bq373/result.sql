/* Median of the per–customer average monthly spend for calendar year 2014 */
SELECT 
    PERCENTILE_CONT(0.5) 
        WITHIN GROUP (ORDER BY "avg_monthly_spend")  AS "median_avg_monthly_spend"
FROM (
        /* yearly total per customer divided by 12 gives average monthly spend */
        SELECT  
            inv."CustomerID",
            SUM(lines."ExtendedPrice") / 12.0  AS "avg_monthly_spend"
        FROM  "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"      AS inv
        JOIN  "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES"  AS lines
              ON inv."InvoiceID" = lines."InvoiceID"
        WHERE EXTRACT(year FROM TO_DATE(inv."InvoiceDate")) = 2014      -- only year 2014
        GROUP BY inv."CustomerID"
) AS per_customer;