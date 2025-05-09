/*  Median of customers’ average monthly spending in 2014               */
/*  – uses ExtendedPrice (already tax-inclusive) from invoice lines      */
WITH line_totals AS (      -- all invoice-line amounts in 2014
    SELECT  i."CustomerID"                       AS customer_id ,
            l."ExtendedPrice"                    AS amount
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      i
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"  l
           ON i."InvoiceID" = l."InvoiceID"
    WHERE   TO_DATE(i."InvoiceDate") >= '2014-01-01'
      AND   TO_DATE(i."InvoiceDate") <  '2015-01-01'
),
customer_total AS (        -- total spend per customer in the year
    SELECT  customer_id ,
            SUM(amount)        AS total_2014
    FROM    line_totals
    GROUP BY customer_id
),
customer_avg AS (          -- average monthly spend (12 calendar months)
    SELECT  customer_id ,
            total_2014 / 12   AS avg_monthly_spend
    FROM    customer_total
)
SELECT  MEDIAN(avg_monthly_spend)  AS median_average_monthly_spending
FROM    customer_avg;