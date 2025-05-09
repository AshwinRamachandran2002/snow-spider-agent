WITH total_orders AS (
    SELECT "employeeid",
           COUNT(*) AS total_orders
    FROM "orders"
    GROUP BY "employeeid"
),
late_orders AS (
    SELECT "employeeid",
           COUNT(*) AS late_orders
    FROM "orders"
    WHERE DATE("shippeddate") >= DATE("requireddate")
    GROUP BY "employeeid"
)
SELECT t."employeeid"                                   AS employee_id,
       COALESCE(l.late_orders, 0)                       AS num_late_orders,
       ROUND(100.0 * COALESCE(l.late_orders, 0) 
                     / t.total_orders, 4)               AS late_order_percent
FROM total_orders t
LEFT JOIN late_orders l
       ON t."employeeid" = l."employeeid"
WHERE t.total_orders > 50
ORDER BY late_order_percent DESC,
         num_late_orders     DESC,
         employee_id         ASC
LIMIT 3;