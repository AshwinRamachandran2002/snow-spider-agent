SELECT cg."groupname" AS "GroupName",
       COUNT(DISTINCT c."customerid") AS "NumberOfCustomers",
       ROUND(COUNT(DISTINCT c."customerid") * 100.0 / (SELECT COUNT(DISTINCT "customerid") FROM "NORTHWIND"."NORTHWIND"."CUSTOMERS"), 4) AS "PercentageOfTotalCustomers"
FROM "NORTHWIND"."NORTHWIND"."CUSTOMERS" c
LEFT JOIN (
    SELECT o."customerid", SUM(od."unitprice" * od."quantity") AS "TotalSpent"
    FROM "NORTHWIND"."NORTHWIND"."ORDERS" o
    JOIN "NORTHWIND"."NORTHWIND"."ORDER_DETAILS" od
      ON o."orderid" = od."orderid"
    WHERE o."orderdate" LIKE '1998%'
    GROUP BY o."customerid"
) ts ON c."customerid" = ts."customerid"
JOIN "NORTHWIND"."NORTHWIND"."CUSTOMERGROUPTHRESHOLD" cg
  ON COALESCE(ts."TotalSpent", 0) BETWEEN cg."rangebottom" AND cg."rangetop"
GROUP BY cg."groupname", cg."rangebottom"
ORDER BY cg."rangebottom" ASC;