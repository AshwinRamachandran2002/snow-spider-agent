WITH customer_spending AS (
    SELECT 
        c.customerid,
        COALESCE(SUM(od.unitprice * od.quantity * (1 - od.discount)), 0) AS total_spent
    FROM customers c
    LEFT JOIN orders o ON c.customerid = o.customerid AND o.orderdate BETWEEN '1998-01-01' AND '1998-12-31'
    LEFT JOIN order_details od ON o.orderid = od.orderid
    GROUP BY c.customerid
)
SELECT 
    ct.groupname AS GroupName,
    COUNT(cs.customerid) AS Number_of_Customers,
    ROUND(100.0 * COUNT(cs.customerid) / (SELECT COUNT(DISTINCT customerid) FROM customers), 4) AS Percentage_of_Total_Customers
FROM customer_spending cs
JOIN customergroupthreshold ct
    ON cs.total_spent BETWEEN ct.rangebottom AND ct.rangetop
GROUP BY ct.groupname
ORDER BY ct.rangebottom;