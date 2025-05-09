/*  Annual sales vs. annual sales-quota, per salesperson  */
WITH
/*------------- 1) Aggregate total sales per salesperson & year -------------*/
orders AS (
    SELECT
        TO_NUMBER("salespersonid")                     AS "SalesPersonID",
        YEAR(TO_DATE("orderdate"))                     AS "SalesYear",
        SUM("totaldue")                                AS "TotalSales"
    FROM ADVENTUREWORKS.ADVENTUREWORKS.SALESORDERHEADER
    WHERE "salespersonid" IS NOT NULL
      AND "salespersonid" <> ''
    GROUP BY
        TO_NUMBER("salespersonid"),
        YEAR(TO_DATE("orderdate"))
),

/*------------- 2) Aggregate annual quota per salesperson & year ------------*/
quota AS (
    SELECT
        "BusinessEntityID"                             AS "SalesPersonID",
        YEAR(TO_DATE("QuotaDate"))                     AS "SalesYear",
        SUM("SalesQuota")                              AS "TotalQuota"
    FROM ADVENTUREWORKS.ADVENTUREWORKS.SALESPERSONQUOTAHISTORY
    GROUP BY
        "BusinessEntityID",
        YEAR(TO_DATE("QuotaDate"))
)

/*------------- 3) Combine and calculate the difference ---------------------*/
SELECT
    COALESCE(o."SalesPersonID", q."SalesPersonID")     AS "SalesPersonID",
    COALESCE(o."SalesYear",      q."SalesYear")        AS "SalesYear",
    o."TotalSales",
    q."TotalQuota",
    (o."TotalSales" - q."TotalQuota")                  AS "SalesMinusQuota"
FROM orders o
FULL OUTER JOIN quota q
  ON o."SalesPersonID" = q."SalesPersonID"
 AND o."SalesYear"      = q."SalesYear"
ORDER BY
    "SalesPersonID",
    "SalesYear";