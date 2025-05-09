WITH customer_totals AS (
    SELECT  o.customerid,
            SUM(od.unitprice * od.quantity) AS total_spent
    FROM    orders AS o
    JOIN    order_details AS od ON o.orderid = od.orderid
    WHERE   strftime('%Y', o.orderdate) = '1998'
    GROUP BY o.customerid
),
grouped AS (
    SELECT  ct.customerid,
            cgt.groupname
    FROM    customer_totals AS ct
    JOIN    customergroupthreshold AS cgt
           ON ct.total_spent BETWEEN cgt.rangebottom AND cgt.rangetop
)
SELECT  g.groupname,
        COUNT(*)                                         AS customers_in_group,
        ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM customer_totals), 2)
                                                        AS pct_of_1998_customers
FROM    grouped AS g
GROUP BY g.groupname
ORDER BY customers_in_group DESC, g.groupname;