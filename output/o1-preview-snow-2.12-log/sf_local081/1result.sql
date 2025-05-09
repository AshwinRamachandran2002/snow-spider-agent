SELECT grp."GroupName",
       COUNT(grp."customerid") AS "NumberOfCustomers",
       ROUND(COUNT(grp."customerid") * 100.0 / total_customers.total_count, 4) AS "PercentageOfTotalCustomers"
FROM (
    SELECT t."customerid",
           t."total_spent",
           cgt."groupname" AS "GroupName"
    FROM (
        SELECT o."customerid",
               SUM(od."unitprice" * od."quantity" * (1 - od."discount")) AS "total_spent"
        FROM "NORTHWIND"."NORTHWIND"."ORDER_DETAILS" od
        JOIN "NORTHWIND"."NORTHWIND"."ORDERS" o
          ON od."orderid" = o."orderid"
        WHERE o."orderdate" LIKE '1998%'
        GROUP BY o."customerid"
    ) t
    JOIN "NORTHWIND"."NORTHWIND"."CUSTOMERGROUPTHRESHOLD" cgt
      ON t."total_spent" >= cgt."rangebottom"
     AND t."total_spent" < cgt."rangetop"
) grp
CROSS JOIN (
    SELECT COUNT(DISTINCT c."customerid") AS total_count
    FROM "NORTHWIND"."NORTHWIND"."CUSTOMERS" c
) total_customers
GROUP BY grp."GroupName", total_customers.total_count
ORDER BY grp."GroupName"
LIMIT 100;