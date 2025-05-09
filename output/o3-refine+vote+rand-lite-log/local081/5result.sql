WITH order_1998 AS (
    -- every order line that was shipped in 1998
    SELECT  o.customerid,
            od.unitprice * od.quantity AS line_total
    FROM    orders              AS o
    JOIN    order_details       AS od  ON od.orderid = o.orderid
    WHERE   strftime('%Y', o.orderdate) = '1998'
),
customer_totals AS (
    -- total 1998 spending per customer (no discounts considered)
    SELECT  customerid,
            SUM(line_total) AS total_spent
    FROM    order_1998
    GROUP BY customerid
),
categorized AS (
    -- put every customer into the proper spending group
    SELECT  ct.customerid,
            ct.total_spent,
            cgt.groupname
    FROM    customer_totals        AS ct
    JOIN    customergroupthreshold AS cgt
           ON ct.total_spent >= cgt.rangebottom
          AND ct.total_spent <= cgt.rangetop
),
group_counts AS (
    -- how many customers in each group
    SELECT  groupname,
            COUNT(*) AS customer_count
    FROM    categorized
    GROUP BY groupname
),
tot_customers AS (
    -- total number of customers that ordered in 1998
    SELECT COUNT(*) AS total_cnt FROM customer_totals
)
SELECT  gc.groupname,
        gc.customer_count,
        ROUND( gc.customer_count * 100.0 / tc.total_cnt , 4) AS percentage_of_1998_customers
FROM    group_counts gc
CROSS JOIN tot_customers tc
ORDER BY gc.groupname;