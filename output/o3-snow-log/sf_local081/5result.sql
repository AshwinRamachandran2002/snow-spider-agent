WITH customer_spend_1998 AS (
    /* 1.  Total amount each customer spent on all 1998 orders                */
    SELECT
        o."customerid",
        SUM(od."unitprice" * od."quantity") AS "total_spent"
    FROM NORTHWIND.NORTHWIND."ORDERS"             o
    JOIN NORTHWIND.NORTHWIND."ORDER_DETAILS"       od
          ON o."orderid" = od."orderid"
    WHERE YEAR(TO_DATE(o."orderdate")) = 1998
    GROUP BY o."customerid"
),
customer_group AS (
    /* 2.  Assign each customer to the appropriate spending group             */
    SELECT
        cs."customerid",
        cs."total_spent",
        cgt."groupname"
    FROM customer_spend_1998                              cs
    LEFT JOIN NORTHWIND.NORTHWIND."CUSTOMERGROUPTHRESHOLD" cgt
           ON cs."total_spent" >= cgt."rangebottom"
          AND cs."total_spent" <= cgt."rangetop"
),
group_stats AS (
    /* 3.  Count customers in each spending group                             */
    SELECT
        cg."groupname",
        COUNT(*) AS "customer_count"
    FROM customer_group cg
    GROUP BY cg."groupname"
),
totals AS (
    /* 4.  Total number of customers who placed orders in 1998                */
    SELECT COUNT(*) AS "total_customers"
    FROM customer_spend_1998
)
SELECT
    gs."groupname",
    gs."customer_count",
    ROUND(gs."customer_count" / t."total_customers" * 100, 4) AS "percentage_of_customers"
FROM group_stats gs
CROSS JOIN totals t
ORDER BY gs."groupname" NULLS LAST;