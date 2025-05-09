WITH emp_stats AS (
    SELECT
        employeeid,
        COUNT(*) AS total_orders,
        SUM(
            CASE
                WHEN shippeddate IS NOT NULL 
                     AND shippeddate >= requireddate THEN 1
                ELSE 0
            END
        ) AS late_orders
    FROM orders
    GROUP BY employeeid
),
filtered AS (
    SELECT
        employeeid,
        late_orders,
        total_orders,
        100.0 * late_orders / total_orders AS late_pct
    FROM emp_stats
    WHERE total_orders > 50
)
SELECT
    employeeid,
    late_orders,
    ROUND(late_pct, 4) AS late_order_percentage
FROM filtered
ORDER BY
    late_pct DESC,
    employeeid
LIMIT 3;