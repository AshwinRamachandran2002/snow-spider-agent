WITH
orders_1998 AS (
    SELECT "orderid",
           "customerid"
    FROM   "orders"
    WHERE  strftime('%Y', "orderdate") = '1998'
),
customer_spent AS (
    SELECT  o."customerid",
            SUM(od."unitprice" * od."quantity") AS totalspent
    FROM    orders_1998       o
    JOIN    "order_details"   od ON od."orderid" = o."orderid"
    GROUP BY o."customerid"
),
customer_group AS (
    SELECT cs."customerid",
           cs.totalspent,
           g."groupname"
    FROM   customer_spent          cs
    JOIN   "customergroupthreshold" g
           ON cs.totalspent >= g."rangebottom"
          AND cs.totalspent <= g."rangetop"
)
SELECT  cg."groupname",
        COUNT(*)                                  AS customer_count,
        ROUND(COUNT(*) * 100.0 / t.total_cust, 4) AS percentage_of_total
FROM    customer_group cg
CROSS JOIN (SELECT COUNT(*) AS total_cust FROM customer_group) t
GROUP BY cg."groupname"
ORDER BY cg."groupname";