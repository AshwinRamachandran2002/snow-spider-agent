WITH
/* yearly total sales taken from each order header */
sales_per_year AS (
    SELECT
        TO_NUMBER("salespersonid")                            AS "salespersonid",
        YEAR("orderdate"::DATE)                               AS "year",
        SUM("totaldue")                                       AS "total_sales"
    FROM ADVENTUREWORKS.ADVENTUREWORKS."SALESORDERHEADER"
    WHERE "salespersonid" IS NOT NULL
          AND "salespersonid" <> ''
    GROUP BY
        TO_NUMBER("salespersonid"),
        YEAR("orderdate"::DATE)
),

/* yearly quota – sum of all quota rows recorded in that year */
quota_per_year AS (
    SELECT
        "BusinessEntityID"                                    AS "salespersonid",
        YEAR("QuotaDate"::DATE)                               AS "year",
        SUM("SalesQuota")                                     AS "total_quota"
    FROM ADVENTUREWORKS.ADVENTUREWORKS."SALESPERSONQUOTAHISTORY"
    GROUP BY
        "BusinessEntityID",
        YEAR("QuotaDate"::DATE)
)

/* compare sales with quota */
SELECT
    COALESCE(s."salespersonid", q."salespersonid")            AS "salespersonid",
    COALESCE(s."year",          q."year")                     AS "year",
    COALESCE(s."total_sales", 0)                              AS "total_sales",
    COALESCE(q."total_quota", 0)                              AS "total_quota",
    COALESCE(s."total_sales", 0) - COALESCE(q."total_quota", 0) 
                                                             AS "sales_minus_quota"
FROM sales_per_year s
FULL OUTER JOIN quota_per_year q
       ON s."salespersonid" = q."salespersonid"
      AND s."year"          = q."year"
ORDER BY
    "salespersonid",
    "year";