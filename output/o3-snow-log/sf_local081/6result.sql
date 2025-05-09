WITH customer_total AS (   -- total 1998 spending per customer
    SELECT
        o."customerid",
        SUM(od."unitprice" * od."quantity") AS total_amount
    FROM NORTHWIND.NORTHWIND.ORDERS          o
    JOIN NORTHWIND.NORTHWIND.ORDER_DETAILS   od
         ON o."orderid" = od."orderid"
    WHERE o."orderdate" LIKE '1998-%'        -- only orders placed in 1998
    GROUP BY o."customerid"
),
customer_group AS (        -- attach spending-group thresholds
    SELECT
        ct."customerid",
        ct.total_amount,
        cgt."groupname"
    FROM customer_total ct
    LEFT JOIN NORTHWIND.NORTHWIND.CUSTOMERGROUPTHRESHOLD cgt
           ON ct.total_amount >= cgt."rangebottom"
          AND ct.total_amount <= cgt."rangetop"
)
SELECT
    COALESCE("groupname", 'Uncategorized')              AS "spending_group",
    COUNT(*)                                            AS "customer_count",
    ROUND(COUNT(*) * 100.0 /
          SUM(COUNT(*)) OVER (), 2)                     AS "percentage_of_total_customers"
FROM customer_group
GROUP BY "groupname"
ORDER BY "customer_count" DESC NULLS LAST;