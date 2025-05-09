WITH orders_with_flag AS (
    SELECT
        "employeeid",
        /* mark as late when shipped date is on/after required date */
        CASE 
            WHEN TO_DATE(NULLIF("shippeddate", '')) >= TO_DATE(NULLIF("requireddate", '')) 
            THEN 1 ELSE 0 
        END AS is_late
    FROM NORTHWIND.NORTHWIND.ORDERS
    WHERE "employeeid" IS NOT NULL
      AND "shippeddate" IS NOT NULL
      AND "requireddate" IS NOT NULL
      AND "shippeddate" <> ''
      AND "requireddate" <> ''
), employee_late_stats AS (
    SELECT
        "employeeid",
        COUNT(*)                              AS total_orders,
        SUM(is_late)                          AS late_orders,
        (SUM(is_late) / COUNT(*)::FLOAT) * 100 AS late_order_percentage
    FROM orders_with_flag
    GROUP BY "employeeid"
    HAVING COUNT(*) > 50                      -- only employees with > 50 total orders
)
SELECT
    "employeeid",
    late_orders,
    ROUND(late_order_percentage, 4) AS late_order_percentage
FROM employee_late_stats
ORDER BY late_order_percentage DESC NULLS LAST, "employeeid"
LIMIT 3;