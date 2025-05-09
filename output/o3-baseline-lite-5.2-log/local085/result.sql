WITH total_orders AS (
    SELECT 
        employeeid,
        COUNT(*) AS total_cnt
    FROM orders
    GROUP BY employeeid
    HAVING total_cnt > 50          -- only employees with more than 50 orders
),
late_orders AS (
    SELECT 
        employeeid,
        COUNT(*) AS late_cnt
    FROM orders
    WHERE shippeddate IS NOT NULL          -- ignore still‑unshipped orders
      AND requireddate IS NOT NULL
      AND shippeddate >= requireddate      -- shipped on/after required ⇒ late
    GROUP BY employeeid
)
SELECT 
    t.employeeid,
    COALESCE(l.late_cnt, 0)                     AS late_orders,
    ROUND( COALESCE(l.late_cnt, 0) * 100.0 
           / t.total_cnt, 4)                   AS late_order_percentage
FROM total_orders AS t
LEFT JOIN late_orders AS l
       ON t.employeeid = l.employeeid
ORDER BY late_order_percentage DESC, t.employeeid
LIMIT 3;