WITH customer_spending AS (
    SELECT "orders"."customerid",
           SUM("order_details"."unitprice" * "order_details"."quantity" * (1 - "order_details"."discount")) AS "customer_total"
    FROM "orders"
    JOIN "order_details" ON "orders"."orderid" = "order_details"."orderid"
    WHERE "orders"."orderdate" LIKE '1998%'
    GROUP BY "orders"."customerid"
),
grouped_customers AS (
    SELECT cgt."groupname",
           cs."customerid"
    FROM customer_spending cs
    JOIN "customergroupthreshold" cgt
    ON cs."customer_total" >= cgt."rangebottom" AND cs."customer_total" < cgt."rangetop"
),
customers_per_group AS (
    SELECT "groupname",
           COUNT(DISTINCT "customerid") AS "number_of_customers"
    FROM grouped_customers
    GROUP BY "groupname"
),
total_customers AS (
    SELECT COUNT(DISTINCT "customerid") AS total_customers
    FROM "customers"
)
SELECT cpg."groupname" AS "GroupName",
       cpg."number_of_customers" AS "Number_of_Customers",
       ROUND((CAST(cpg."number_of_customers" AS FLOAT) / tc.total_customers) * 100, 4) AS "Percentage_of_Total_Customers"
FROM customers_per_group cpg, total_customers tc
ORDER BY cpg."groupname";