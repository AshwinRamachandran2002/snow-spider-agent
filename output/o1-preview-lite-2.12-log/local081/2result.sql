WITH customer_totals AS (
  SELECT
    c.customerid,
    COALESCE(SUM(od.unitprice * od.quantity * (1 - od.discount)), 0) AS customer_total
  FROM
    customers c
    LEFT JOIN orders o ON c.customerid = o.customerid AND o.orderdate BETWEEN '1998-01-01' AND '1998-12-31'
    LEFT JOIN order_details od ON o.orderid = od.orderid
  GROUP BY
    c.customerid
),
customer_groups AS (
  SELECT
    c.customerid,
    c.customer_total,
    g.groupname
  FROM
    customer_totals c
    JOIN customergroupthreshold g ON c.customer_total BETWEEN g.rangebottom AND g.rangetop
),
group_counts AS (
  SELECT
    c.groupname,
    COUNT(DISTINCT c.customerid) AS number_of_customers
  FROM
    customer_groups c
  GROUP BY
    c.groupname
),
total_customers AS (
  SELECT
    COUNT(DISTINCT customerid) AS total_customers
  FROM
    customers
)
SELECT
  gc.groupname AS "GroupName",
  gc.number_of_customers AS "Number_of_Customers",
  ROUND((gc.number_of_customers * 100.0) / tc.total_customers, 4) AS "Percentage_of_Total_Customers"
FROM
  group_counts gc,
  total_customers tc
ORDER BY
  gc.groupname;