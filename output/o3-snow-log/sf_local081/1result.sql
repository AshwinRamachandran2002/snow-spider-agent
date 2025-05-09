WITH
/* 1. Orders placed in 1998 */
orders_1998 AS (
    SELECT
        "orderid",
        "customerid"
    FROM NORTHWIND.NORTHWIND.ORDERS
    WHERE YEAR(TO_DATE("orderdate")) = 1998
),

/* 2. Total spend per customer (ignore discounts) */
customer_spend AS (
    SELECT
        o."customerid",
        SUM(od."unitprice" * od."quantity") AS "total_spent"
    FROM orders_1998            o
    JOIN NORTHWIND.NORTHWIND.ORDER_DETAILS od
      ON o."orderid" = od."orderid"
    GROUP BY o."customerid"
),

/* 3. Assign each customer to a spending group */
customer_grouped AS (
    SELECT
        cs."customerid",
        cs."total_spent",
        COALESCE(cgt."groupname", 'Unassigned') AS "spending_group"
    FROM customer_spend cs
    LEFT JOIN NORTHWIND.NORTHWIND.CUSTOMERGROUPTHRESHOLD cgt
           ON cs."total_spent" >= cgt."rangebottom"
          AND cs."total_spent" <= cgt."rangetop"
),

/* 4. Total number of distinct customers who ordered in 1998 */
total_customers AS (
    SELECT COUNT(*) AS "total_cnt"
    FROM customer_grouped
)

/* 5. Final stats: count & percentage per spending group */
SELECT
    cg."spending_group",
    COUNT(*)                                                  AS "customers_in_group",
    ROUND(COUNT(*) / tc."total_cnt" * 100, 2)                 AS "percentage_of_total_customers"
FROM customer_grouped cg
CROSS JOIN total_customers tc
GROUP BY
    cg."spending_group",
    tc."total_cnt"
ORDER BY
    "customers_in_group" DESC NULLS LAST;