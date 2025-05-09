SELECT
  employee_id,
  late_orders,
  late_order_percentage
FROM (
    SELECT
        t.employeeid AS employee_id,
        COALESCE(l.late_orders, 0) AS late_orders,
        ROUND(COALESCE(l.late_orders, 0) * 100.0 / t.total_orders, 4) AS late_order_percentage
    FROM (
        SELECT
            employeeid,
            COUNT(*) AS total_orders
        FROM orders
        GROUP BY employeeid
    ) AS t
    LEFT JOIN (
        SELECT
            employeeid,
            COUNT(*) AS late_orders
        FROM orders
        WHERE shippeddate IS NOT NULL
          AND requireddate IS NOT NULL
          AND shippeddate >= requireddate
        GROUP BY employeeid
    ) AS l
      ON t.employeeid = l.employeeid
    WHERE t.total_orders > 50
)
ORDER BY
  late_order_percentage DESC,
  employee_id
LIMIT 3;