WITH
-- 1. Annual quota per salesperson
quota AS (
    SELECT 
        "BusinessEntityID"        AS "SalesPersonID",
        strftime('%Y',"QuotaDate") AS "Year",
        SUM("SalesQuota")          AS "AnnualQuota"
    FROM "SalesPersonQuotaHistory"
    GROUP BY "BusinessEntityID", strftime('%Y',"QuotaDate")
),
-- 2. Annual total sales per salesperson
sales AS (
    SELECT
        "salespersonid"           AS "SalesPersonID",
        strftime('%Y',"orderdate") AS "Year",
        SUM("totaldue")            AS "AnnualSales"
    FROM "salesorderheader"
    GROUP BY "salespersonid", strftime('%Y',"orderdate")
),
-- 3. Full outer join of the two aggregates
combined AS (
    /* quotas (with or without matching sales) */
    SELECT
        q."SalesPersonID",
        q."Year",
        s."AnnualSales",
        q."AnnualQuota"
    FROM quota q
    LEFT JOIN sales s
           ON s."SalesPersonID" = q."SalesPersonID"
          AND s."Year"          = q."Year"
    
    UNION ALL
    
    /* sales that have no matching quota */
    SELECT
        s."SalesPersonID",
        s."Year",
        s."AnnualSales",
        NULL AS "AnnualQuota"
    FROM sales s
    LEFT JOIN quota q
           ON q."SalesPersonID" = s."SalesPersonID"
          AND q."Year"          = s."Year"
    WHERE q."SalesPersonID" IS NULL
)
-- 4. Final result with difference
SELECT
    "SalesPersonID",
    "Year",
    COALESCE("AnnualSales",0) AS "AnnualSales",
    COALESCE("AnnualQuota",0) AS "AnnualQuota",
    COALESCE("AnnualSales",0) - COALESCE("AnnualQuota",0) AS "Difference"
FROM combined
ORDER BY "SalesPersonID", "Year";