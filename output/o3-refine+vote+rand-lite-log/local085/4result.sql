WITH emp_orders AS (
    SELECT
        employeeid,
        COUNT(*) AS total_orders,
        SUM(CASE
                WHEN shippeddate IS NOT NULL
                     AND shippeddate >= requireddate
                THEN 1
                ELSE 0
            END) AS late_orders
    FROM orders
    GROUP BY employeeid
),
emp_filtered AS (
    SELECT
        employeeid,
        late_orders,
        total_orders,
        (late_orders * 1.0 / total_orders) * 100 AS late_percentage
    FROM emp_orders
    WHERE total_orders > 50
)
SELECT
    employeeid      AS EmployeeID,
    late_orders     AS LateOrders,
    ROUND(late_percentage, 4) AS LateOrderPercentage
FROM emp_filtered
ORDER BY late_percentage DESC,
         employeeid
LIMIT 3;