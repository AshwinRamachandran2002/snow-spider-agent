WITH customer_totals AS (               -- total spent by each customer in 1998
    SELECT  o.customerid,
            SUM(od.unitprice * od.quantity) AS total_spent
    FROM    orders          AS o
    JOIN    order_details   AS od ON od.orderid = o.orderid
    WHERE   strftime('%Y', o.orderdate) = '1998'
    GROUP BY o.customerid
),
customer_groups AS (                    -- map each customer to a spending group
    SELECT  ct.customerid,
            cgt.groupname
    FROM    customer_totals        AS ct
    JOIN    customergroupthreshold AS cgt
           ON ct.total_spent BETWEEN cgt.rangebottom AND cgt.rangetop
),
totals AS (                             -- total number of 1998 customers
    SELECT COUNT(DISTINCT customerid) AS total_customers
    FROM   customer_groups
)
SELECT  cgt.groupname,
        COALESCE(COUNT(DISTINCT cg.customerid), 0)                           AS customer_count,
        ROUND(
            COALESCE(COUNT(DISTINCT cg.customerid), 0) * 100.0 /
            (SELECT total_customers FROM totals), 4)                         AS percentage_of_customers
FROM    customergroupthreshold AS cgt
LEFT JOIN customer_groups      AS cg  ON cg.groupname = cgt.groupname
CROSS JOIN totals
GROUP BY cgt.groupname
ORDER BY cgt.groupname;