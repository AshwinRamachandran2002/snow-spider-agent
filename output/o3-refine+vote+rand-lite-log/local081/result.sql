WITH orders_1998 AS (
    SELECT "orderid",
           "customerid"
    FROM "orders"
    WHERE "orderdate" BETWEEN '1998-01-01' AND '1998-12-31'
),
customer_totals AS (
    SELECT o."customerid",
           SUM(od."unitprice" * od."quantity") AS total_spent
    FROM orders_1998 o
    JOIN "order_details" od
      ON od."orderid" = o."orderid"
    GROUP BY o."customerid"
),
customer_groups AS (
    SELECT ct."customerid",
           ct.total_spent,
           cgt."groupname"
    FROM customer_totals ct
    JOIN "customergroupthreshold" cgt
         ON ct.total_spent >= cgt."rangebottom"
        AND ct.total_spent <= cgt."rangetop"
),
totals AS (
    SELECT COUNT(*) AS total_customers
    FROM customer_totals
)
SELECT cg."groupname",
       COUNT(*) AS customer_count,
       ROUND(100.0 * COUNT(*) / (SELECT total_customers FROM totals), 4) AS percentage_of_total
FROM customer_groups cg
GROUP BY cg."groupname"
ORDER BY cg."groupname";