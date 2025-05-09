WITH "orders_parsed" AS (
    SELECT
        "employeeid",
        TRY_TO_DATE("shippeddate")   AS "shipped_dt",
        TRY_TO_DATE("requireddate")  AS "req_dt"
    FROM NORTHWIND.NORTHWIND.ORDERS
), 
"emp_orders" AS (
    SELECT
        "employeeid",
        COUNT(*) AS "total_orders",
        SUM(
            CASE 
                WHEN "shipped_dt" IS NOT NULL 
                     AND "req_dt" IS NOT NULL 
                     AND "shipped_dt" >= "req_dt"
                THEN 1 ELSE 0 
            END
        ) AS "late_orders"
    FROM "orders_parsed"
    GROUP BY "employeeid"
), 
"emp_filtered" AS (
    SELECT
        "employeeid",
        "late_orders",
        "total_orders",
        ("late_orders" * 100.0) / "total_orders" AS "late_pct"
    FROM "emp_orders"
    WHERE "total_orders" > 50
)
SELECT
    "employeeid",
    "late_orders",
    ROUND("late_pct", 4) AS "late_order_percentage"
FROM "emp_filtered"
ORDER BY "late_pct" DESC NULLS LAST
LIMIT 3;