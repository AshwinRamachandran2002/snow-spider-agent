-- Annual sales vs. annual quota per salesperson
WITH sales_tot AS (       -- yearly total sales per salesperson
    SELECT
        CAST("salespersonid" AS NUMBER)         AS salesperson_id,
        YEAR(TO_DATE("orderdate"))              AS sales_year,
        SUM("totaldue")                         AS total_sales
    FROM ADVENTUREWORKS.ADVENTUREWORKS.SALESORDERHEADER
    WHERE "salespersonid" IS NOT NULL AND "salespersonid" <> ''
    GROUP BY salesperson_id, sales_year
),
quota_tot AS (            -- yearly aggregated quota per salesperson
    SELECT
        "BusinessEntityID"                      AS salesperson_id,
        YEAR(TO_DATE("QuotaDate"))              AS sales_year,
        SUM("SalesQuota")                       AS annual_quota
    FROM ADVENTUREWORKS.ADVENTUREWORKS.SALESPERSONQUOTAHISTORY
    GROUP BY salesperson_id, sales_year
)
SELECT
    COALESCE(s.salesperson_id, q.salesperson_id)                    AS salesperson_id,
    COALESCE(s.sales_year,       q.sales_year)                      AS year,
    COALESCE(s.total_sales, 0)                                      AS total_sales,
    COALESCE(q.annual_quota, 0)                                     AS annual_quota,
    COALESCE(s.total_sales, 0) - COALESCE(q.annual_quota, 0)        AS difference
FROM sales_tot  s
FULL OUTER JOIN quota_tot q
  ON s.salesperson_id = q.salesperson_id
 AND s.sales_year      = q.sales_year
ORDER BY salesperson_id, year NULLS LAST;