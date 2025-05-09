SELECT
    employeeid AS employee_id,
    SUM(CASE WHEN shippeddate >= requireddate THEN 1 ELSE 0 END) AS late_orders,
    ROUND(
        100.0 * SUM(CASE WHEN shippeddate >= requireddate THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS late_order_percentage
FROM orders
GROUP BY employeeid
HAVING COUNT(*) > 50
ORDER BY late_order_percentage DESC
LIMIT 3;