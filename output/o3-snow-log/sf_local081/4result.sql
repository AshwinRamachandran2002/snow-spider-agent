/* 1) get 1998 orders
   2) compute each customer’s 1998 spending (unitprice * quantity, ignore discount)
   3) map every customer to a spending group using CUSTOMERGROUPTHRESHOLD
   4) count customers per group and calculate share of total                */
WITH orders_1998 AS (
    SELECT
        "orderid",
        "customerid"
    FROM NORTHWIND.NORTHWIND.ORDERS
    WHERE YEAR(TO_DATE("orderdate")) = 1998
),
customer_spending AS (
    SELECT
        o."customerid",
        SUM(od."unitprice" * od."quantity") AS total_spent
    FROM orders_1998            o
    JOIN NORTHWIND.NORTHWIND.ORDER_DETAILS od
      ON od."orderid" = o."orderid"
    GROUP BY o."customerid"
),
assigned_group AS (
    SELECT
        cs."customerid",
        cs.total_spent,
        cg."groupname"
    FROM customer_spending                       cs
    JOIN NORTHWIND.NORTHWIND.CUSTOMERGROUPTHRESHOLD cg
      ON cs.total_spent >= cg."rangebottom"
     AND cs.total_spent <= cg."rangetop"
),
totals AS (
    SELECT COUNT(DISTINCT "customerid") AS total_customers
    FROM assigned_group
)
SELECT
    ag."groupname",
    COUNT(DISTINCT ag."customerid")                                                AS customer_count,
    ROUND(COUNT(DISTINCT ag."customerid") * 100.0 / t.total_customers, 2)          AS percentage_of_total
FROM assigned_group ag
CROSS JOIN totals t
GROUP BY ag."groupname", t.total_customers
ORDER BY customer_count DESC NULLS LAST;