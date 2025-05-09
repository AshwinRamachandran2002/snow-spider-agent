WITH months AS (                                                       -- 12 months of 2014
    SELECT seq4() + 1 AS month_num
    FROM TABLE(GENERATOR(ROWCOUNT => 12))
),  

customers AS (                                                         -- every customer that bought in 2014
    SELECT DISTINCT
           i."CustomerID"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES" i
    WHERE EXTRACT(year FROM TO_DATE(i."InvoiceDate")) = 2014
),  

spend_by_cust_month AS (                                               -- spend per customer-month
    SELECT
        i."CustomerID",
        EXTRACT(month FROM TO_DATE(i."InvoiceDate")) AS month_num,
        SUM(l."ExtendedPrice") AS month_spend
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     i
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICELINES" l
      ON i."InvoiceID" = l."InvoiceID"
    WHERE EXTRACT(year FROM TO_DATE(i."InvoiceDate")) = 2014
    GROUP BY
        i."CustomerID",
        month_num
),  

cust_month_matrix AS (                                                 -- ensure one row per customer * 12 months
    SELECT
        c."CustomerID",
        m.month_num,
        COALESCE(s.month_spend, 0) AS month_spend
    FROM customers c
    CROSS JOIN months m
    LEFT JOIN spend_by_cust_month s
           ON s."CustomerID" = c."CustomerID"
          AND s.month_num   = m.month_num
),  

customer_avg AS (                                                      -- average monthly spend per customer
    SELECT
        "CustomerID",
        AVG(month_spend) AS avg_monthly_spend
    FROM cust_month_matrix
    GROUP BY "CustomerID"
)  

SELECT                                                                 -- median of those averages
    MEDIAN(avg_monthly_spend) AS median_avg_monthly_spend
FROM customer_avg;