WITH total_orders AS (
    SELECT
        employeeid,
        COUNT(*) AS total_cnt
    FROM orders
    GROUP BY employeeid
    HAVING COUNT(*) > 50
),
late_orders AS (
    SELECT
        employeeid,
        COUNT(*) AS late_cnt
    FROM orders
    WHERE shippeddate IS NOT NULL
      AND requireddate IS NOT NULL
      AND shippeddate >= requireddate
    GROUP BY employeeid
)
SELECT
    t.employeeid                         AS employee_id,
    COALESCE(l.late_cnt, 0)              AS late_order_count,
    ROUND(
        (CAST(COALESCE(l.late_cnt, 0) AS REAL) * 100.0) / t.total_cnt,
        4
    )                                    AS late_order_percentage
FROM total_orders AS t
LEFT JOIN late_orders AS l
       ON t.employeeid = l.employeeid
ORDER BY late_order_percentage DESC
LIMIT 3;