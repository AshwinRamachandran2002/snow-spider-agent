WITH total AS (
    SELECT employeeid,
           COUNT(*) AS total_orders
    FROM orders
    GROUP BY employeeid
    HAVING COUNT(*) > 50
),
late AS (
    SELECT employeeid,
           COUNT(*) AS late_orders
    FROM orders
    WHERE shippeddate IS NOT NULL
      AND requireddate IS NOT NULL
      AND DATE(shippeddate) >= DATE(requireddate)
    GROUP BY employeeid
)
SELECT t.employeeid,
       COALESCE(l.late_orders, 0) AS late_orders,
       ROUND(100.0 * COALESCE(l.late_orders, 0) / t.total_orders, 4) AS late_pct
FROM total t
LEFT JOIN late l ON t.employeeid = l.employeeid
ORDER BY late_pct DESC
LIMIT 3;