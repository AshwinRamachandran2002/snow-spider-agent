WITH per_emp AS (
    SELECT
        employeeid,
        SUM(CASE WHEN shippeddate >= requireddate THEN 1 ELSE 0 END) AS late_orders,
        COUNT(*)                                                     AS total_orders
    FROM orders
    WHERE shippeddate IS NOT NULL
    GROUP BY employeeid
    HAVING COUNT(*) > 50
)
SELECT
    employeeid                                   AS employee_id,
    late_orders,
    ROUND(100.0 * late_orders / total_orders, 4) AS late_order_percentage
FROM per_emp
ORDER BY late_order_percentage DESC, employee_id
LIMIT 3;