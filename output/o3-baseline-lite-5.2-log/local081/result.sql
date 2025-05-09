WITH orders_1998 AS (
    SELECT "orderid",
           "customerid"
    FROM   "orders"
    WHERE  "orderdate" >= '1998-01-01'
       AND "orderdate" <  '1999-01-01'
),
customer_spending AS (
    SELECT  o."customerid",
            SUM(od."unitprice" * od."quantity") AS total_spent
    FROM    orders_1998 o
    JOIN    "order_details" od
            ON od."orderid" = o."orderid"
    GROUP BY o."customerid"
),
total_customers AS (
    SELECT COUNT(*) AS cnt
    FROM   customer_spending
),
customer_group AS (
    SELECT  cs."customerid",
            cgt."groupname"
    FROM    customer_spending cs
    JOIN    "customergroupthreshold" cgt
            ON cs.total_spent BETWEEN cgt."rangebottom" AND cgt."rangetop"
)
SELECT   cg."groupname",
         COUNT(DISTINCT cg."customerid")                                         AS customer_count,
         ROUND(COUNT(DISTINCT cg."customerid") * 100.0 /
               (SELECT cnt FROM total_customers), 4)                             AS percentage_of_total
FROM     customer_group cg
GROUP BY cg."groupname"
ORDER BY cg."groupname";