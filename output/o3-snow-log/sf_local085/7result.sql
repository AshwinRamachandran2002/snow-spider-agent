WITH order_stats AS (
    SELECT
        "employeeid",
        COUNT(*)                                    AS total_orders,
        SUM(
            IFF(
                TRY_TO_DATE("shippeddate") >= TRY_TO_DATE("requireddate"),
                1, 
                0
            )
        )                                           AS late_orders
    FROM NORTHWIND.NORTHWIND.ORDERS
    GROUP BY "employeeid"
    HAVING COUNT(*) > 50                 -- only employees with > 50 total orders
),
calc AS (
    SELECT
        "employeeid",
        late_orders,
        (late_orders::FLOAT / total_orders) * 100   AS late_percentage
    FROM order_stats
)
SELECT
    "employeeid",
    late_orders,
    ROUND(late_percentage, 4) AS late_order_percentage
FROM calc
ORDER BY late_percentage DESC NULLS LAST
LIMIT 3;