WITH sales_totals AS (
    SELECT 
        TO_NUMBER("salespersonid")                                   AS "SalesPersonID",
        EXTRACT(YEAR FROM TO_DATE("orderdate"))                      AS "SalesYear",
        SUM("totaldue")                                              AS "TotalSales"
    FROM ADVENTUREWORKS.ADVENTUREWORKS.SALESORDERHEADER
    WHERE "salespersonid" IS NOT NULL 
      AND "salespersonid" <> ''
    GROUP BY 
        TO_NUMBER("salespersonid"),
        EXTRACT(YEAR FROM TO_DATE("orderdate"))
),
quota_totals AS (
    SELECT 
        "BusinessEntityID"                                           AS "SalesPersonID",
        EXTRACT(YEAR FROM TO_DATE("QuotaDate"))                      AS "SalesYear",
        SUM("SalesQuota")                                            AS "TotalQuota"
    FROM ADVENTUREWORKS.ADVENTUREWORKS.SALESPERSONQUOTAHISTORY
    GROUP BY 
        "BusinessEntityID",
        EXTRACT(YEAR FROM TO_DATE("QuotaDate"))
)
SELECT
    COALESCE(s."SalesPersonID", q."SalesPersonID")                   AS "SalesPersonID",
    COALESCE(s."SalesYear",     q."SalesYear")                       AS "Year",
    COALESCE(s."TotalSales", 0)                                      AS "TotalSales",
    COALESCE(q."TotalQuota", 0)                                      AS "TotalQuota",
    COALESCE(s."TotalSales",0) - COALESCE(q."TotalQuota",0)          AS "Difference"
FROM sales_totals s
FULL JOIN quota_totals q
       ON s."SalesPersonID" = q."SalesPersonID"
      AND s."SalesYear"     = q."SalesYear"
ORDER BY 
    "SalesPersonID",
    "Year";