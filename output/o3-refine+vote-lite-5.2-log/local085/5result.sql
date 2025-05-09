WITH employee_orders AS (
    SELECT
        employeeid,
        COUNT(*) AS total_orders,
        SUM(CASE
                WHEN shippeddate IS NOT NULL
                     AND DATE(shippeddate) >= DATE(requireddate) THEN 1
                ELSE 0
            END) AS late_orders
    FROM orders
    GROUP BY employeeid
),
employee_stats AS (
    SELECT
        employeeid,
        late_orders,
        total_orders,
        (late_orders * 100.0) / total_orders AS late_percentage
    FROM employee_orders
    WHERE total_orders > 50
)
SELECT
    employeeid,
    late_orders,
    ROUND(late_percentage, 4) AS late_order_percentage
FROM employee_stats
ORDER BY late_percentage DESC, employeeid
LIMIT 3;