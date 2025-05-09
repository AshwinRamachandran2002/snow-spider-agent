/*----------------------------------------------------------
  Annual sales vs. annual quota per salesperson
----------------------------------------------------------*/
WITH "sales_totals" AS (          -- annual total sales
    SELECT
        TO_NUMBER("salespersonid")               AS "SalesPersonID",
        YEAR(TO_DATE("orderdate"))               AS "Year",
        SUM("totaldue")                          AS "TotalSales"
    FROM ADVENTUREWORKS.ADVENTUREWORKS.SALESORDERHEADER
    WHERE "salespersonid" IS NOT NULL
      AND "salespersonid" <> ''
    GROUP BY
        TO_NUMBER("salespersonid"),
        YEAR(TO_DATE("orderdate"))
),
"quota_totals" AS (               -- annual sales quota
    SELECT
        "BusinessEntityID"                       AS "SalesPersonID",
        YEAR(TO_DATE("QuotaDate"))               AS "Year",
        SUM("SalesQuota")                        AS "AnnualQuota"
    FROM ADVENTUREWORKS.ADVENTUREWORKS.SALESPERSONQUOTAHISTORY
    GROUP BY
        "BusinessEntityID",
        YEAR(TO_DATE("QuotaDate"))
)

SELECT
    COALESCE(s."SalesPersonID", q."SalesPersonID")                     AS "SalesPersonID",
    COALESCE(s."Year",          q."Year")                              AS "Year",
    COALESCE(s."TotalSales", 0)                                         AS "TotalSales",
    COALESCE(q."AnnualQuota", 0)                                        AS "AnnualQuota",
    COALESCE(s."TotalSales", 0) - COALESCE(q."AnnualQuota", 0)          AS "Difference"
FROM "sales_totals" s
FULL OUTER JOIN "quota_totals" q
  ON s."SalesPersonID" = q."SalesPersonID"
 AND s."Year"         = q."Year"
ORDER BY "SalesPersonID", "Year" NULLS LAST;