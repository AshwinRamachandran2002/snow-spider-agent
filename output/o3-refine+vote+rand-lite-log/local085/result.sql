WITH order_stats AS (
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
qualified AS (
    SELECT
        employeeid,
        late_orders,
        total_orders,
        (late_orders * 100.0) / total_orders AS late_pct
    FROM order_stats
    WHERE total_orders > 50
)
SELECT
    employeeid,
    late_orders,
    ROUND(late_pct, 4) AS late_order_percentage
FROM qualified
ORDER BY late_pct DESC, employeeid
LIMIT 3;