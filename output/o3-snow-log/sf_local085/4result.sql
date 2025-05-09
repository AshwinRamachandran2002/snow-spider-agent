WITH orders AS (
    SELECT
        "employeeid",
        TRY_TO_DATE("requireddate") AS req_date,
        TRY_TO_DATE("shippeddate")  AS ship_date
    FROM NORTHWIND.NORTHWIND."ORDERS"
),
emp_stats AS (
    SELECT
        "employeeid",
        COUNT(*)                                                     AS total_orders,
        SUM(CASE 
                WHEN ship_date IS NOT NULL 
                     AND req_date IS NOT NULL
                     AND ship_date >= req_date 
                THEN 1 
                ELSE 0 
            END)                                                    AS late_orders
    FROM orders
    GROUP BY "employeeid"
    HAVING COUNT(*) > 50
),
emp_pct AS (
    SELECT
        "employeeid",
        late_orders,
        ROUND(late_orders * 100.0 / total_orders, 4) AS late_percentage
    FROM emp_stats
)
SELECT
    "employeeid",
    late_orders,
    late_percentage
FROM emp_pct
ORDER BY late_percentage DESC NULLS LAST, "employeeid"
LIMIT 3;