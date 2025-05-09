/* 1. Pull orders placed in 1998 */
WITH orders_1998 AS (
    SELECT "orderid",
           "customerid"
    FROM   NORTHWIND.NORTHWIND.ORDERS
    WHERE  YEAR(TO_DATE("orderdate")) = 1998
),

/* 2. Compute each customer’s total spend in 1998 (ignore discounts) */
customer_totals AS (
    SELECT  o."customerid",
            SUM(od."unitprice" * od."quantity") AS total_spent
    FROM    orders_1998                o
    JOIN    NORTHWIND.NORTHWIND.ORDER_DETAILS od
           ON o."orderid" = od."orderid"
    GROUP BY o."customerid"
),

/* 3. Assign every customer to a spending group based on thresholds */
assigned_groups AS (
    SELECT  ct."customerid",
            ct.total_spent,
            cg."groupname"
    FROM    customer_totals                          ct
    LEFT JOIN NORTHWIND.NORTHWIND.CUSTOMERGROUPTHRESHOLD cg
           ON ct.total_spent >= cg."rangebottom"
          AND ct.total_spent <= cg."rangetop"
),

/* 4. Count customers in each group (use “Uncategorized” if no match) */
group_counts AS (
    SELECT  COALESCE("groupname", 'Uncategorized') AS groupname,
            COUNT(*)                                AS num_customers
    FROM     assigned_groups
    GROUP BY COALESCE("groupname", 'Uncategorized')
),

/* 5. Total number of customers who placed orders in 1998 */
total_customers AS (
    SELECT SUM(num_customers) AS total_count
    FROM   group_counts
)

/* 6. Final result: count and percentage by spending group */
SELECT  gc.groupname,
        gc.num_customers,
        ROUND(gc.num_customers * 100.0 / tc.total_count, 2) AS percentage_of_total
FROM    group_counts   gc
CROSS JOIN total_customers tc
ORDER BY gc.num_customers DESC NULLS LAST;