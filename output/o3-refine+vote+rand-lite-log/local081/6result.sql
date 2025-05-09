WITH orders_1998 AS (
    SELECT orderid,
           customerid
    FROM orders
    WHERE orderdate BETWEEN '1998-01-01' AND '1998-12-31'
),
customer_totals AS (
    SELECT o.customerid,
           SUM(od.unitprice * od.quantity) AS total_spent
    FROM orders_1998 o
    JOIN order_details od USING (orderid)
    GROUP BY o.customerid
),
customer_groups AS (
    SELECT ct.customerid,
           ct.total_spent,
           cgt.groupname
    FROM customer_totals ct
    JOIN customergroupthreshold cgt
      ON ct.total_spent >= cgt.rangebottom
     AND ct.total_spent <= cgt.rangetop
),
group_stats AS (
    SELECT groupname,
           COUNT(*) AS customers_in_group
    FROM customer_groups
    GROUP BY groupname
),
totals AS (
    SELECT COUNT(*) AS total_customers
    FROM customer_groups
)
SELECT 
    gs.groupname,
    gs.customers_in_group,
    ROUND(gs.customers_in_group * 100.0 / t.total_customers, 4) AS percentage_of_total
FROM group_stats gs
CROSS JOIN totals t
ORDER BY gs.groupname;