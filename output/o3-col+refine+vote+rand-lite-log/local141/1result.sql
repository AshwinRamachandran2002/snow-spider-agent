WITH sales AS (
    SELECT  "salespersonid",
            SUBSTR("orderdate", 1, 4) AS "year",
            SUM("totaldue")           AS "annual_sales"
    FROM    "salesorderheader"
    WHERE   "salespersonid" IS NOT NULL
    GROUP BY "salespersonid", "year"
),
quota AS (
    SELECT  "BusinessEntityID"        AS "salespersonid",
            SUBSTR("QuotaDate", 1, 4) AS "year",
            SUM("SalesQuota")         AS "annual_quota"
    FROM    "SalesPersonQuotaHistory"
    GROUP BY "BusinessEntityID", "year"
)
SELECT  s."salespersonid",
        s."year",
        s."annual_sales",
        q."annual_quota",
        ROUND(s."annual_sales" - COALESCE(q."annual_quota", 0), 4) AS "difference"
FROM    sales  AS s
LEFT JOIN quota AS q
       ON s."salespersonid" = q."salespersonid"
      AND s."year"          = q."year"
ORDER BY s."salespersonid",
         s."year";