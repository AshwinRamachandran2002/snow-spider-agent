WITH orders_1998 AS (
    SELECT 
        orderid, 
        customerid
    FROM orders
    WHERE strftime('%Y', orderdate) = '1998'
),
customer_totals AS (
    SELECT 
        o.customerid,
        SUM(od.unitprice * od.quantity) AS total_spent
    FROM orders_1998 AS o
    JOIN order_details AS od
        ON od.orderid = o.orderid
    GROUP BY o.customerid
),
customer_group AS (
    SELECT 
        ct.customerid,
        ct.total_spent,
        cgt.groupname
    FROM customer_totals AS ct
    JOIN customergroupthreshold AS cgt
        ON ct.total_spent >= cgt.rangebottom
       AND ct.total_spent <= cgt.rangetop
)
SELECT
    cg.groupname,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_totals), 4) AS percentage_of_total
FROM customer_group AS cg
GROUP BY cg.groupname
ORDER BY cg.groupname;