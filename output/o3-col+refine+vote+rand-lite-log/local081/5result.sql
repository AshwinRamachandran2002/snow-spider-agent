WITH customer_totals AS (
    SELECT  o."customerid",
            SUM(od."unitprice" * od."quantity") AS "total_spent"
    FROM    "orders"        AS o
    JOIN    "order_details" AS od
           ON od."orderid" = o."orderid"
    WHERE   strftime('%Y', o."orderdate") = '1998'
    GROUP BY o."customerid"
),
total_customers AS (
    SELECT COUNT(*) AS "cnt"
    FROM   customer_totals
)
SELECT  cg."groupname",
        COUNT(*)                                   AS "customer_count",
        ROUND(100.0 * COUNT(*) / tc."cnt", 2)      AS "percentage_of_total"
FROM    customer_totals        AS ct
JOIN    "customergroupthreshold" AS cg
       ON ct."total_spent" BETWEEN cg."rangebottom" AND cg."rangetop"
CROSS JOIN total_customers      AS tc
GROUP BY cg."groupname"
ORDER BY cg."groupname";