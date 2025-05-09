SELECT
    sub.employeeid AS employee_id,
    sub.late_orders,
    ROUND(sub.late_orders * 100.0 / sub.total_orders, 4) AS late_order_percentage
FROM (
    SELECT
        employeeid,
        COUNT(*) AS total_orders,
        SUM(CASE WHEN shippeddate >= requireddate THEN 1 ELSE 0 END) AS late_orders
    FROM orders
    GROUP BY employeeid
    HAVING COUNT(*) > 50
) AS sub
ORDER BY late_order_percentage DESC, employee_id
LIMIT 3;