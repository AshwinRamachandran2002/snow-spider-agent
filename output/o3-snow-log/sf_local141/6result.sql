/*  Annual sales vs. annual quota per salesperson  */
WITH sales AS (   -- yearly total sales from SalesOrderHeader
    SELECT
        TO_NUMBER("salespersonid")                                         AS "SalesPersonID",
        EXTRACT(YEAR FROM TO_DATE("orderdate", 'YYYY-MM-DD HH24:MI:SS'))   AS "Year",
        SUM("totaldue")                                                    AS "Total_Sales"
    FROM ADVENTUREWORKS.ADVENTUREWORKS.SALESORDERHEADER
    WHERE "salespersonid" IS NOT NULL
          AND "salespersonid" <> ''        -- ignore orders without a salesperson
    GROUP BY
        TO_NUMBER("salespersonid"),
        EXTRACT(YEAR FROM TO_DATE("orderdate", 'YYYY-MM-DD HH24:MI:SS'))
),

quota AS (   -- yearly quota from SalesPersonQuotaHistory
    SELECT
        "BusinessEntityID"                                                 AS "SalesPersonID",
        EXTRACT(YEAR FROM TO_DATE("QuotaDate", 'YYYY-MM-DD HH24:MI:SS'))   AS "Year",
        SUM("SalesQuota")                                                  AS "Annual_Quota"
    FROM ADVENTUREWORKS.ADVENTUREWORKS.SALESPERSONQUOTAHISTORY
    GROUP BY
        "BusinessEntityID",
        EXTRACT(YEAR FROM TO_DATE("QuotaDate", 'YYYY-MM-DD HH24:MI:SS'))
),

combined AS (  -- bring the two together, keeping all combinations
    SELECT
        COALESCE(s."SalesPersonID", q."SalesPersonID")    AS "SalesPersonID",
        COALESCE(s."Year",         q."Year")              AS "Year",
        COALESCE(s."Total_Sales",  0)                     AS "Total_Sales",
        COALESCE(q."Annual_Quota", 0)                     AS "Annual_Quota"
    FROM sales s
    FULL OUTER JOIN quota q
           ON s."SalesPersonID" = q."SalesPersonID"
          AND s."Year"          = q."Year"
)

SELECT
    "SalesPersonID",
    "Year",
    "Total_Sales",
    "Annual_Quota",
    ("Total_Sales" - "Annual_Quota")  AS "Difference"
FROM combined
ORDER BY
    "SalesPersonID",
    "Year";