WITH order_dates AS (
    SELECT
        "employeeid",
        TRY_TO_DATE("requireddate")  AS req_date,
        TRY_TO_DATE("shippeddate")   AS ship_date
    FROM NORTHWIND.NORTHWIND.ORDERS
),
employee_stats AS (
    SELECT
        "employeeid",
        COUNT(*)                                             AS total_orders,
        COUNT_IF(ship_date >= req_date)                      AS late_orders,
        ROUND(COUNT_IF(ship_date >= req_date)::FLOAT 
              / COUNT(*) * 100, 4)                           AS late_percentage
    FROM order_dates
    GROUP BY "employeeid"
    HAVING COUNT(*) > 50
)
SELECT
    "employeeid",
    late_orders,
    late_percentage
FROM employee_stats
ORDER BY late_percentage DESC NULLS LAST
LIMIT 3;