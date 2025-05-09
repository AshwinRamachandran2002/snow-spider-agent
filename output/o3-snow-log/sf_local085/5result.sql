WITH employee_orders AS (
    SELECT
        "employeeid",
        COUNT(*) AS total_orders,
        COUNT_IF(
            TRY_TO_DATE("shippeddate") IS NOT NULL
            AND TRY_TO_DATE("requireddate") IS NOT NULL
            AND TRY_TO_DATE("shippeddate") >= TRY_TO_DATE("requireddate")
        ) AS late_orders
    FROM "NORTHWIND"."NORTHWIND"."ORDERS"
    GROUP BY "employeeid"
),
eligible_employees AS (
    SELECT
        "employeeid",
        late_orders,
        total_orders,
        (late_orders / total_orders::FLOAT) * 100 AS late_percentage
    FROM employee_orders
    WHERE total_orders > 50
)
SELECT
    "employeeid",
    late_orders,
    ROUND(late_percentage, 4) AS late_order_percentage
FROM eligible_employees
ORDER BY late_percentage DESC NULLS LAST
LIMIT 3;