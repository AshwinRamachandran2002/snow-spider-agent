WITH
    total_spending_per_customer AS (
        SELECT
            ORDERS."customerid",
            SUM("ORDER_DETAILS"."unitprice" * "ORDER_DETAILS"."quantity" * (1 - "ORDER_DETAILS"."discount")) AS "total_spending"
        FROM
            NORTHWIND.NORTHWIND.ORDERS AS ORDERS
            JOIN NORTHWIND.NORTHWIND.ORDER_DETAILS AS "ORDER_DETAILS"
                ON ORDERS."orderid" = "ORDER_DETAILS"."orderid"
        WHERE
            ORDERS."orderdate" >= '1998-01-01'
            AND ORDERS."orderdate" < '1999-01-01'
            AND ORDERS."customerid" IS NOT NULL
        GROUP BY
            ORDERS."customerid"
    ),
    total_customers AS (
        SELECT
            COUNT(DISTINCT "customerid") AS "total_customers"
        FROM
            NORTHWIND.NORTHWIND.ORDERS
        WHERE
            "orderdate" >= '1998-01-01'
            AND "orderdate" < '1999-01-01'
            AND "customerid" IS NOT NULL
    ),
    customers_with_groups AS (
        SELECT
            ts."customerid",
            ts."total_spending",
            cgt."groupname",
            cgt."rangebottom"
        FROM
            total_spending_per_customer ts
            JOIN NORTHWIND.NORTHWIND.CUSTOMERGROUPTHRESHOLD cgt
                ON ts."total_spending" >= cgt."rangebottom"
                AND ts."total_spending" <= cgt."rangetop"
    ),
    group_counts AS (
        SELECT
            cwg."groupname",
            cwg."rangebottom",
            COUNT(DISTINCT cwg."customerid") AS "NumberOfCustomers"
        FROM
            customers_with_groups cwg
        GROUP BY
            cwg."groupname", cwg."rangebottom"
    ),
    group_percentages AS (
        SELECT
            gc."groupname" AS "GroupName",
            gc."NumberOfCustomers",
            ROUND((gc."NumberOfCustomers" * 100.0) / tc."total_customers", 4) AS "PercentageOfTotalCustomers",
            gc."rangebottom"
        FROM
            group_counts gc
            CROSS JOIN total_customers tc
    )
SELECT
    gp."GroupName",
    gp."NumberOfCustomers",
    gp."PercentageOfTotalCustomers"
FROM
    group_percentages gp
ORDER BY
    gp."rangebottom";