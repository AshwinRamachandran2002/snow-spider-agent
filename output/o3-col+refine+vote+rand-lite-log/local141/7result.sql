WITH yearly_sales AS (
    SELECT 
        "salespersonid"                       AS salesperson_id,
        SUBSTR("orderdate",1,4)               AS year,
        SUM("subtotal")                       AS total_sales
    FROM "salesorderheader"
    WHERE "salespersonid" IS NOT NULL
    GROUP BY "salespersonid", SUBSTR("orderdate",1,4)
),
yearly_quota AS (
    SELECT 
        "BusinessEntityID"                    AS salesperson_id,
        SUBSTR("QuotaDate",1,4)               AS year,
        SUM("SalesQuota")                     AS total_quota
    FROM "SalesPersonQuotaHistory"
    GROUP BY "BusinessEntityID", SUBSTR("QuotaDate",1,4)
)
SELECT
    s.salesperson_id,
    s.year,
    s.total_sales,
    COALESCE(q.total_quota, 0)                AS total_quota,
    s.total_sales - COALESCE(q.total_quota,0) AS sales_minus_quota
FROM yearly_sales s
LEFT JOIN yearly_quota q
       ON s.salesperson_id = q.salesperson_id
      AND s.year           = q.year
ORDER BY
    s.salesperson_id,
    s.year;