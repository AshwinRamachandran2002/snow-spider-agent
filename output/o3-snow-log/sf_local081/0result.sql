WITH "orders_1998" AS (
    SELECT 
        "orderid",
        "customerid"
    FROM NORTHWIND.NORTHWIND.ORDERS
    WHERE "orderdate" >= '1998-01-01'
      AND "orderdate" <  '1999-01-01'
),
"customer_totals" AS (
    SELECT 
        o."customerid",
        SUM(od."unitprice" * od."quantity") AS "total_spent"
    FROM "orders_1998" o
    JOIN NORTHWIND.NORTHWIND.ORDER_DETAILS od
      ON o."orderid" = od."orderid"
    GROUP BY o."customerid"
),
"customer_group" AS (
    SELECT
        ct."customerid",
        ct."total_spent",
        COALESCE(cgt."groupname", 'No Group') AS "groupname"
    FROM "customer_totals" ct
    LEFT JOIN NORTHWIND.NORTHWIND.CUSTOMERGROUPTHRESHOLD cgt
      ON ct."total_spent" >= cgt."rangebottom"
     AND ct."total_spent" <= cgt."rangetop"
),
"group_counts" AS (
    SELECT
        "groupname",
        COUNT(*) AS "customer_count"
    FROM "customer_group"
    GROUP BY "groupname"
),
"totals" AS (
    SELECT COUNT(*) AS "total_customers"
    FROM "customer_group"
)
SELECT
    gc."groupname",
    gc."customer_count",
    ROUND(gc."customer_count" * 100.0 / t."total_customers", 4) AS "percentage_of_customers"
FROM "group_counts" gc
CROSS JOIN "totals" t
ORDER BY gc."customer_count" DESC NULLS LAST;