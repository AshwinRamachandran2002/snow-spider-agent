WITH months AS (                                    -- all 12 months of 2014
    SELECT DATEADD(month, seq4(), '2014-01-01'::date)   AS month_start
    FROM   TABLE(GENERATOR(ROWCOUNT => 12))
),
invoice_lines_2014 AS (                            -- total line amounts per customer & month
    SELECT  i."CustomerID",
            DATE_TRUNC('month', TO_DATE(i."InvoiceDate",'YYYY-MM-DD'))  AS month_start,
            SUM(l."ExtendedPrice")                                    AS month_spend
    FROM    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"      i
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES"  l
           ON l."InvoiceID" = i."InvoiceID"
    WHERE   TO_DATE(i."InvoiceDate",'YYYY-MM-DD')
            BETWEEN '2014-01-01'::date AND '2014-12-31'::date
    GROUP BY i."CustomerID",
             DATE_TRUNC('month', TO_DATE(i."InvoiceDate",'YYYY-MM-DD'))
),
customers AS (                                    -- customers that bought anything in 2014
    SELECT DISTINCT "CustomerID"
    FROM   invoice_lines_2014
),
customer_months AS (                              -- every customer-month combination
    SELECT  c."CustomerID",
            m.month_start
    FROM    customers c
    CROSS   JOIN months m
),
customer_month_spend AS (                         -- attach spend, zero if none
    SELECT  cm."CustomerID",
            cm.month_start,
            COALESCE(il.month_spend, 0) AS month_spend
    FROM    customer_months     cm
    LEFT JOIN invoice_lines_2014 il
           ON il."CustomerID" = cm."CustomerID"
          AND il.month_start   = cm.month_start
),
customer_avg_monthly AS (                         -- average monthly spend per customer
    SELECT  "CustomerID",
            AVG(month_spend) AS avg_month_spend
    FROM    customer_month_spend
    GROUP BY "CustomerID"
)
SELECT  MEDIAN(avg_month_spend) AS median_of_avg_month_spend_2014
FROM    customer_avg_monthly;