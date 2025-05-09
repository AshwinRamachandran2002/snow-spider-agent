WITH customer_totals AS (
    SELECT  o.customerid,
            SUM(od.unitprice * od.quantity) AS total_spent
    FROM    orders o
    JOIN    order_details od ON od.orderid = o.orderid
    WHERE   strftime('%Y', o.orderdate) = '1998'
    GROUP BY o.customerid
),
total_customers AS (
    SELECT COUNT(*) AS cnt
    FROM   customer_totals
),
grouped AS (
    SELECT  ct.groupname AS spending_group,
            c.customerid
    FROM    customer_totals c
    JOIN    customergroupthreshold ct
           ON c.total_spent BETWEEN ct.rangebottom AND ct.rangetop
)
SELECT  g.spending_group,
        COUNT(DISTINCT g.customerid)                                       AS customers,
        ROUND(COUNT(DISTINCT g.customerid) * 100.0 /
              (SELECT cnt FROM total_customers), 4)                        AS percentage_of_1998_customers
FROM    grouped g
GROUP BY g.spending_group
ORDER BY g.spending_group;