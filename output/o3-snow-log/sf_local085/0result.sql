WITH ORDERS_CTE AS (
    SELECT
        "employeeid",
        COUNT(*)                                        AS total_orders,
        SUM(
            CASE
                WHEN TRY_TO_DATE("shippeddate") >= TRY_TO_DATE("requireddate") THEN 1
                ELSE 0
            END
        )                                               AS late_orders
    FROM NORTHWIND.NORTHWIND.ORDERS
    GROUP BY "employeeid"
),
FILTERED AS (
    SELECT
        "employeeid",
        late_orders,
        total_orders,
        (late_orders / total_orders::FLOAT) * 100       AS late_percentage
    FROM ORDERS_CTE
    WHERE total_orders > 50
)
SELECT
    "employeeid"                                        AS "EMPLOYEEID",
    late_orders                                         AS "LATE_ORDERS",
    ROUND(late_percentage, 4)                           AS "LATE_ORDER_PERCENTAGE"
FROM FILTERED
ORDER BY late_percentage DESC NULLS LAST
LIMIT 3;