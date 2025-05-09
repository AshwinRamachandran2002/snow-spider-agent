WITH cust1998 AS (
    /* 1) Total spent (no discount) by each customer on 1998 orders */
    SELECT  o.customerid,
            SUM(od.unitprice * od.quantity) AS total_spent
    FROM    orders          AS o
    JOIN    order_details   AS od ON od.orderid = o.orderid
    WHERE   o.orderdate LIKE '1998%'          -- keep only 1998 orders
    GROUP BY o.customerid
),
cust_grouped AS (
    /* 2) Assign every 1998-customer to a spending group */
    SELECT  c98.customerid,
            ct.groupname
    FROM    cust1998              AS c98
    JOIN    customergroupthreshold AS ct
           ON c98.total_spent BETWEEN ct.rangebottom AND ct.rangetop
),
totals AS (
    /* 3) Number of distinct 1998 customers (for percentage calc) */
    SELECT COUNT(*) AS total_customers
    FROM   cust1998
)
SELECT  cg.groupname,
        COUNT(*)                                    AS customer_count,
        ROUND(100.0 * COUNT(*) / t.total_customers, 4) AS percentage_of_total
FROM    cust_grouped AS cg
CROSS JOIN totals        AS t
GROUP BY cg.groupname
ORDER BY cg.groupname;