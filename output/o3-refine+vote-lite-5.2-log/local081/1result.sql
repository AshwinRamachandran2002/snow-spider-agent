WITH customer_spend AS (
    /* total amount spent (ignoring discount) by each customer with orders in 1998 */
    SELECT
        o.customerid,
        SUM(od.unitprice * od.quantity) AS total_spent
    FROM orders AS o
    JOIN order_details AS od
         ON od.orderid = o.orderid
    WHERE o.orderdate BETWEEN '1998-01-01' AND '1998-12-31'
    GROUP BY o.customerid
),
customer_group AS (
    /* put every customer into its spending group */
    SELECT
        cs.customerid,
        cs.total_spent,
        cgt.groupname
    FROM customer_spend AS cs
    JOIN customergroupthreshold AS cgt
         ON cs.total_spent BETWEEN cgt.rangebottom AND cgt.rangetop
),
group_counts AS (
    /* number of customers in every spending group */
    SELECT
        cg.groupname,
        COUNT(*) AS customer_count
    FROM customer_group AS cg
    GROUP BY cg.groupname
),
total_customers AS (
    /* total customers who placed orders in 1998 */
    SELECT COUNT(*) AS total_customer_cnt
    FROM customer_spend
)
SELECT
    gc.groupname,
    gc.customer_count,
    ROUND(gc.customer_count * 100.0 / tc.total_customer_cnt, 4) AS percentage_of_customers
FROM group_counts AS gc
CROSS JOIN total_customers AS tc
ORDER BY gc.groupname;