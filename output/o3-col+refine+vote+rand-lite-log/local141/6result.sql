WITH
-- annual sales-quota per salesperson
quota AS (
    SELECT
        "BusinessEntityID"              AS salesperson_id,
        substr("QuotaDate",1,4)         AS year,
        SUM("SalesQuota")               AS annual_quota
    FROM "SalesPersonQuotaHistory"
    GROUP BY "BusinessEntityID", substr("QuotaDate",1,4)
),
-- annual total sales (TotalDue) per salesperson
sales AS (
    SELECT
        "salespersonid"                 AS salesperson_id,
        substr("orderdate",1,4)         AS year,
        SUM("totaldue")                 AS annual_sales
    FROM "salesorderheader"
    WHERE "salespersonid" IS NOT NULL
    GROUP BY "salespersonid", substr("orderdate",1,4)
),
-- emulate FULL OUTER JOIN so every salesperson/year from either set is kept
combined AS (
    -- rows that have a quota record (left side)
    SELECT
        q.salesperson_id,
        q.year,
        s.annual_sales,
        q.annual_quota
    FROM quota q
    LEFT JOIN sales s
      ON s.salesperson_id = q.salesperson_id
     AND s.year           = q.year

    UNION ALL

    -- rows that have sales but no quota (right-only rows)
    SELECT
        s.salesperson_id,
        s.year,
        s.annual_sales,
        NULL AS annual_quota
    FROM sales s
    LEFT JOIN quota q
      ON q.salesperson_id = s.salesperson_id
     AND q.year           = s.year
    WHERE q.salesperson_id IS NULL
)
SELECT
    salesperson_id,
    year,
    annual_sales,
    annual_quota,
    COALESCE(annual_sales,0) - COALESCE(annual_quota,0) AS sales_minus_quota
FROM combined
ORDER BY salesperson_id, year;