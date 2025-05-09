WITH customer_totals AS (
    -- total amount (no discounts) each customer spent on 1998 orders
    SELECT  o.customerid,
            SUM(od.unitprice * od.quantity) AS customer_total
    FROM    orders         AS o
    JOIN    order_details  AS od ON od.orderid = o.orderid
    WHERE   strftime('%Y', o.orderdate) = '1998'
    GROUP BY o.customerid
),
classified AS (
    -- match every customer total to the appropriate spending group
    SELECT  ct.customerid,
            ct.customer_total,
            cgt.groupname
    FROM    customer_totals        AS ct
    JOIN    customergroupthreshold AS cgt
           ON ct.customer_total BETWEEN cgt.rangebottom AND cgt.rangetop
),
tot AS (
    -- total number of customers who placed orders in 1998
    SELECT COUNT(*) AS total_customers
    FROM   customer_totals
)
SELECT  c.groupname                                    AS groupname,
        COUNT(*)                                       AS customers_in_group,
        ROUND(100.0 * COUNT(*) / tot.total_customers,
              2) || '%'                                AS percent_of_1998_customers
FROM    classified AS c
CROSS JOIN tot
GROUP BY c.groupname
ORDER BY c.groupname;