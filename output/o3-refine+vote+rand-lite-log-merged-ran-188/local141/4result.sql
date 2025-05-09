WITH yearly_sales AS (
    /* total sales per salesperson per calendar year */
    SELECT
        "salespersonid"                   AS salesperson_id,
        strftime('%Y',"orderdate")        AS year,
        SUM("totaldue")                   AS total_sales
    FROM "salesorderheader"
    WHERE "salespersonid" IS NOT NULL
    GROUP BY "salespersonid", year
),
yearly_quota AS (
    /* yearly sales‑quota (sum of monthly quotas) per salesperson */
    SELECT
        "BusinessEntityID"                AS salesperson_id,
        strftime('%Y',"QuotaDate")        AS year,
        SUM("SalesQuota")                 AS annual_quota
    FROM "SalesPersonQuotaHistory"
    GROUP BY "BusinessEntityID", year
),
combined AS (
    /* match the two sets; bring across rows missing on either side */
    SELECT
        s.salesperson_id,
        s.year,
        s.total_sales,
        q.annual_quota
    FROM yearly_sales s
    LEFT JOIN yearly_quota q
           ON q.salesperson_id = s.salesperson_id
          AND q.year           = s.year

    UNION

    SELECT
        q.salesperson_id,
        q.year,
        s.total_sales,
        q.annual_quota
    FROM yearly_quota q
    LEFT JOIN yearly_sales s
           ON s.salesperson_id = q.salesperson_id
          AND s.year           = q.year
    WHERE s.salesperson_id IS NULL          -- keep only quotas without matching sales
)
SELECT
    salesperson_id,
    year,
    COALESCE(total_sales,0)     AS total_sales,
    COALESCE(annual_quota,0)    AS annual_quota,
    COALESCE(total_sales,0) - 
    COALESCE(annual_quota,0)    AS difference   -- positive = exceeded quota, negative = missed
FROM combined
ORDER BY salesperson_id, year;