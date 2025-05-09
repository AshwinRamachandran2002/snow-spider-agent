WITH "customer_spend" AS (
    SELECT  o."customerid",
            SUM(d."unitprice" * d."quantity") AS "total_spent"
    FROM    "orders"        AS o
    JOIN    "order_details" AS d ON d."orderid" = o."orderid"
    WHERE   o."orderdate" LIKE '1998-%'
    GROUP BY o."customerid"
),
"grouped" AS (
    SELECT  cs."customerid",
            cs."total_spent",
            cg."groupname"
    FROM    "customer_spend"         AS cs
    JOIN    "customergroupthreshold" AS cg
      ON    cs."total_spent" >= cg."rangebottom"
      AND   cs."total_spent" <= cg."rangetop"
)
SELECT  g."groupname",
        COUNT(*) AS "customer_count",
        ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM "grouped"), 2) AS "percentage_of_total"
FROM    "grouped" AS g
GROUP BY g."groupname"
ORDER BY "customer_count" DESC;