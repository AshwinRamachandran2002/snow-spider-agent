WITH months AS (   -- 12 months of year 2014
    SELECT DATE_TRUNC('month', DATEADD(month, seq4(), '2014-01-01'::date))         AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 12))
),

invoice_totals AS (   -- total extended price per customer per month in 2014
    SELECT
        I."CustomerID",
        DATE_TRUNC('month', TO_DATE(I."InvoiceDate"))                               AS month_start,
        SUM(IL."ExtendedPrice")                                                     AS month_total
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      I
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES"  IL
           ON IL."InvoiceID" = I."InvoiceID"
    WHERE  TO_DATE(I."InvoiceDate") BETWEEN '2014-01-01' AND '2014-12-31'
    GROUP  BY I."CustomerID",
             DATE_TRUNC('month', TO_DATE(I."InvoiceDate"))
),

customer_list AS (   -- customers having at least one invoice in 2014
    SELECT DISTINCT "CustomerID"
    FROM   invoice_totals
),

all_months AS (      -- every customer crossed with the 12 months (missing months will be 0)
    SELECT cl."CustomerID", m.month_start
    FROM   customer_list cl
    CROSS  JOIN months m
),

customer_month_totals AS (
    SELECT 
        am."CustomerID",
        am.month_start,
        COALESCE(it.month_total, 0) AS month_total
    FROM   all_months      am
    LEFT  JOIN invoice_totals it
           ON  it."CustomerID" = am."CustomerID"
           AND it.month_start  = am.month_start
),

avg_monthly_spend AS (   -- average monthly spend per customer across the 12 months
    SELECT 
        "CustomerID",
        AVG(month_total) AS avg_month_spend
    FROM   customer_month_totals
    GROUP  BY "CustomerID"
)

-- median of those average monthly spends
SELECT MEDIAN(avg_month_spend) AS median_average_monthly_spending
FROM   avg_monthly_spend;