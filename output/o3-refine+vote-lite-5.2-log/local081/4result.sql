WITH "customer_spending_1998" AS (
    SELECT
        o.customerid,
        SUM(od.unitprice * od.quantity) AS total_spent
    FROM orders AS o
    JOIN order_details AS od
      ON od.orderid = o.orderid
    WHERE o.orderdate >= '1998-01-01'
      AND o.orderdate < '1999-01-01'
    GROUP BY o.customerid
),
"classified" AS (
    SELECT
        cs.customerid,
        cs.total_spent,
        cgt.groupname
    FROM "customer_spending_1998" AS cs
    JOIN customergroupthreshold AS cgt
      ON cs.total_spent >= cgt.rangebottom
     AND cs.total_spent <= cgt.rangetop
),
"totals" AS (
    SELECT COUNT(*) AS total_customers
    FROM "customer_spending_1998"
)
SELECT
    c.groupname,
    COUNT(DISTINCT c.customerid) AS customer_count,
    ROUND(
        COUNT(DISTINCT c.customerid) * 100.0 / t.total_customers,
        4
    ) AS percentage_of_total
FROM "classified" AS c
CROSS JOIN "totals" AS t
GROUP BY c.groupname
ORDER BY c.groupname;