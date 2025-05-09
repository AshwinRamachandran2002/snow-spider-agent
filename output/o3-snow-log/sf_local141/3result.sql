/*----------------------------------------------------------
  Annual sales vs. annual sales quota per salesperson
-----------------------------------------------------------*/
WITH annual_quota AS (      -- yearly sum of monthly quotas
    SELECT
        "BusinessEntityID"                      AS "salespersonid",
        YEAR(TO_DATE("QuotaDate"))              AS "year",
        SUM("SalesQuota")                       AS "annual_sales_quota"
    FROM ADVENTUREWORKS.ADVENTUREWORKS.SALESPERSONQUOTAHISTORY
    GROUP BY
        "BusinessEntityID",
        YEAR(TO_DATE("QuotaDate"))
),
annual_sales AS (           -- yearly total sales (TotalDue)
    SELECT
        CAST("salespersonid" AS NUMBER)         AS "salespersonid",
        YEAR(TO_DATE("orderdate"))              AS "year",
        SUM("totaldue")                         AS "annual_total_sales"
    FROM ADVENTUREWORKS.ADVENTUREWORKS.SALESORDERHEADER
    WHERE "salespersonid" IS NOT NULL
      AND TRIM("salespersonid") <> ''
    GROUP BY
        CAST("salespersonid" AS NUMBER),
        YEAR(TO_DATE("orderdate"))
)
SELECT
    COALESCE(s."salespersonid", q."salespersonid")          AS "salespersonid",
    COALESCE(s."year",          q."year")                   AS "year",
    s."annual_total_sales",
    q."annual_sales_quota",
    NVL(s."annual_total_sales", 0) -
    NVL(q."annual_sales_quota", 0)                          AS "sales_minus_quota"
FROM annual_sales s
FULL JOIN annual_quota q
       ON s."salespersonid" = q."salespersonid"
      AND s."year"         = q."year"
ORDER BY
    "salespersonid",
    "year";