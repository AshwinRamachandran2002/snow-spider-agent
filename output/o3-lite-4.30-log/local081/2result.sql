WITH customer_spend AS (
    SELECT o.customerid,
           SUM(od.unitprice * od.quantity) AS total_spent
    FROM orders        AS o
    JOIN order_details AS od ON od.orderid = o.orderid
    WHERE substr(o.orderdate, 1, 4) = '1998'
    GROUP BY o.customerid
),
classified AS (
    SELECT cs.customerid,
           cgt.groupname
    FROM customer_spend         AS cs
    JOIN customergroupthreshold AS cgt
         ON cs.total_spent BETWEEN cgt.rangebottom AND cgt.rangetop
),
totals AS (
    SELECT COUNT(*) AS total_customers
    FROM customer_spend
)
SELECT
    c.groupname                                         AS spending_group,
    COUNT(*)                                            AS customers,
    ROUND(100.0 * COUNT(*) / t.total_customers, 4)      AS percentage_of_1998_customers
FROM classified AS c
CROSS JOIN totals   AS t
GROUP BY c.groupname
ORDER BY customers DESC, spending_group;