SELECT
    grp."groupname",
    grp."customers_in_group",
    ROUND(100.0 * grp."customers_in_group" / tot."total_customers_1998", 2) AS "pct_of_1998_customers"
FROM (
    /* 1. 1998 customers with their total spend (no discounts) */
    SELECT
        ct."groupname",
        COUNT(*) AS "customers_in_group"
    FROM (
        SELECT
            o."customerid",
            SUM(od."unitprice" * od."quantity") AS "customer_spent_1998"
        FROM "orders" AS o
        JOIN "order_details" AS od
          ON od."orderid" = o."orderid"
        WHERE substr(o."orderdate", 1, 4) = '1998'
        GROUP BY o."customerid"
    ) AS c98
    /* 2. Map each customer’s spend to the appropriate spending group */
    JOIN "customergroupthreshold" AS ct
      ON c98."customer_spent_1998" BETWEEN ct."rangebottom" AND ct."rangetop"
    GROUP BY ct."groupname"
) AS grp
/* 3. Total number of customers who ordered in 1998 */
CROSS JOIN (
    SELECT COUNT(DISTINCT "customerid") AS "total_customers_1998"
    FROM "orders"
    WHERE substr("orderdate", 1, 4) = '1998'
) AS tot
ORDER BY grp."groupname";