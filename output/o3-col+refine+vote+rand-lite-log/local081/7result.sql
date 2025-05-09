WITH
customer_totals AS (
    SELECT
        o."customerid",
        SUM(od."unitprice" * od."quantity") AS "customer_total"
    FROM "orders" AS o
    JOIN "order_details" AS od
      ON od."orderid" = o."orderid"
    WHERE o."orderdate" LIKE '1998-%'
    GROUP BY o."customerid"
),
customer_group AS (
    SELECT
        ct."customerid",
        thr."groupname" AS "spending_group"
    FROM customer_totals AS ct
    JOIN "customergroupthreshold" AS thr
      ON ct."customer_total" BETWEEN thr."rangebottom" AND thr."rangetop"
),
group_counts AS (
    SELECT
        cg."spending_group",
        COUNT(*) AS "customers_in_group"
    FROM customer_group AS cg
    GROUP BY cg."spending_group"
),
total_customers AS (
    SELECT COUNT(*) AS "total_customers"
    FROM customer_totals
)
SELECT
    gc."spending_group",
    gc."customers_in_group",
    ROUND(100.0 * gc."customers_in_group" / tc."total_customers", 2) AS "percentage_of_customers"
FROM group_counts AS gc
CROSS JOIN total_customers AS tc
ORDER BY gc."spending_group";