WITH spend AS (
    SELECT o."customerid",
           SUM(od."unitprice" * od."quantity") AS total_spent
    FROM "orders" AS o
    JOIN "order_details" AS od ON od."orderid" = o."orderid"
    WHERE o."orderdate" LIKE '1998-%'
    GROUP BY o."customerid"
),
tagged AS (
    SELECT s."customerid",
           s.total_spent,
           g."groupname"
    FROM spend AS s
    JOIN "customergroupthreshold" AS g
      ON s.total_spent BETWEEN g."rangebottom" AND g."rangetop"
),
totals AS (
    SELECT COUNT(*) AS total_customers_1998 FROM tagged
)
SELECT t."groupname",
       COUNT(*) AS num_customers,
       ROUND(100.0 * COUNT(*) / (SELECT total_customers_1998 FROM totals), 4) AS percentage_of_1998_customers
FROM tagged AS t
GROUP BY t."groupname"
ORDER BY t."groupname";