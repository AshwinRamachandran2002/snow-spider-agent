WITH customer_totals AS (
    SELECT  o."customerid",
            SUM(od."unitprice" * od."quantity") AS total_spent
    FROM    "orders"        AS o
    JOIN    "order_details" AS od ON od."orderid" = o."orderid"
    WHERE   strftime('%Y', o."orderdate") = '1998'
    GROUP BY o."customerid"
),
total_customers AS (
    SELECT COUNT(*) AS cnt
    FROM   customer_totals
),
customer_groups AS (
    SELECT  cgt."groupname" AS spending_group,
            COUNT(*)        AS customers
    FROM    customer_totals            AS ct
    JOIN    "customergroupthreshold"   AS cgt
           ON ct.total_spent BETWEEN cgt."rangebottom" AND cgt."rangetop"
    GROUP BY cgt."groupname"
)
SELECT  spending_group,
        customers,
        ROUND(100.0 * customers / (SELECT cnt FROM total_customers), 4) 
        AS percentage_of_1998_customers
FROM    customer_groups
ORDER BY customers DESC, spending_group;