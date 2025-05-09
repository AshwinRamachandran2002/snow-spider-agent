WITH orders_parsed AS (
    SELECT
        "employeeid",
        TO_DATE(NULLIF("shippeddate", ''), 'YYYY-MM-DD')  AS shipped_dt,
        TO_DATE(NULLIF("requireddate", ''), 'YYYY-MM-DD') AS req_dt
    FROM NORTHWIND.NORTHWIND."ORDERS"
),
orders_flag AS (
    SELECT
        "employeeid",
        CASE
            WHEN shipped_dt IS NOT NULL
                 AND req_dt IS NOT NULL
                 AND shipped_dt >= req_dt THEN 1
            ELSE 0
        END AS late_ind
    FROM orders_parsed
),
employee_stats AS (
    SELECT
        "employeeid",
        COUNT(*)                        AS total_orders,
        SUM(late_ind)                   AS late_orders
    FROM orders_flag
    GROUP BY "employeeid"
    HAVING COUNT(*) > 50               -- employees with more than 50 orders
)
SELECT
    "employeeid"                                                        AS "employee_id",
    late_orders,
    ROUND(late_orders::FLOAT / total_orders * 100, 4)                   AS "late_order_percentage"
FROM employee_stats
ORDER BY "late_order_percentage" DESC NULLS LAST
LIMIT 3;