WITH customer_totals_1998 AS (
    -- Total amount each customer spent in 1998 (no discount considered)
    SELECT o."customerid",
           SUM(od."unitprice" * od."quantity") AS customer_total
    FROM "orders"          AS o
    JOIN "order_details"   AS od ON od."orderid" = o."orderid"
    WHERE strftime('%Y', o."orderdate") = '1998'
    GROUP BY o."customerid"
),
customers_per_group AS (
    -- Assign customers to spending groups and count them
    SELECT g."groupname",
           COUNT(*) AS customer_count
    FROM customer_totals_1998        AS ct
    JOIN "customergroupthreshold"    AS g
      ON ct.customer_total BETWEEN g."rangebottom" AND g."rangetop"
    GROUP BY g."groupname"
),
total_customers AS (
    -- Total distinct customers who ordered in 1998
    SELECT COUNT(*) AS total_cnt
    FROM customer_totals_1998
)
SELECT cpg."groupname",
       cpg."customer_count",
       ROUND(100.0 * cpg."customer_count" / tc.total_cnt, 4) AS "percentage_of_total"
FROM customers_per_group AS cpg
CROSS JOIN total_customers AS tc
ORDER BY cpg."groupname";