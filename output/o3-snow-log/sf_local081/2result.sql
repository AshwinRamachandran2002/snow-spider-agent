WITH customers_1998 AS (   -- every order line shipped in 1998
    SELECT
        o."customerid",
        od."unitprice" * od."quantity" AS line_total
    FROM NORTHWIND.NORTHWIND.ORDERS         o
    JOIN NORTHWIND.NORTHWIND.ORDER_DETAILS  od ON o."orderid" = od."orderid"
    WHERE TO_DATE(o."orderdate") BETWEEN '1998-01-01' AND '1998-12-31'
      AND o."customerid" IS NOT NULL
),
customer_totals AS (       -- total spend per customer
    SELECT
        "customerid",
        SUM(line_total) AS total_spent
    FROM customers_1998
    GROUP BY "customerid"
),
customer_group AS (        -- map each customer to a threshold group
    SELECT
        ct."customerid",
        ct.total_spent,
        COALESCE(cgt."groupname", 'Unknown') AS "groupname"
    FROM customer_totals ct
    LEFT JOIN NORTHWIND.NORTHWIND.CUSTOMERGROUPTHRESHOLD cgt
           ON ct.total_spent >= cgt."rangebottom"
          AND ct.total_spent <= cgt."rangetop"
),
summary AS (               -- count customers in each group
    SELECT
        "groupname",
        COUNT(DISTINCT "customerid") AS customer_count
    FROM customer_group
    GROUP BY "groupname"
),
total_customers AS (       -- total distinct customers in 1998
    SELECT COUNT(DISTINCT "customerid") AS total_cnt FROM customer_group
)
SELECT
    s."groupname",
    s.customer_count,
    ROUND(s.customer_count / t.total_cnt * 100, 4) AS percentage_of_total
FROM summary s
CROSS JOIN total_customers t
ORDER BY s.customer_count DESC NULLS LAST;