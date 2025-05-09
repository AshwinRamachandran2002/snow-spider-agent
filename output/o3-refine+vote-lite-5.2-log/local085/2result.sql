WITH per_employee AS (
    SELECT
        employeeid,
        COUNT(*) AS total_orders,
        SUM(
            CASE
                WHEN shippeddate IS NOT NULL
                     AND julianday(shippeddate) >= julianday(requireddate)
                THEN 1 ELSE 0
            END
        ) AS late_orders
    FROM orders
    GROUP BY employeeid
),
qualified AS (
    SELECT
        employeeid,
        late_orders,
        100.0 * late_orders / total_orders AS late_percentage
    FROM per_employee
    WHERE total_orders > 50
)
SELECT
    employeeid,
    late_orders,
    ROUND(late_percentage, 4) AS late_order_percentage
FROM qualified
ORDER BY late_percentage DESC, employeeid
LIMIT 3;