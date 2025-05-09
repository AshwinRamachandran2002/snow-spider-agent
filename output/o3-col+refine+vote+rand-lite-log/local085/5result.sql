WITH tot AS (
    SELECT "employeeid",
           COUNT(*) AS total_orders
    FROM "orders"
    GROUP BY "employeeid"
    HAVING COUNT(*) > 50
),
late AS (
    SELECT "employeeid",
           COUNT(*) AS late_orders
    FROM "orders"
    WHERE "shippeddate" IS NOT NULL
      AND "requireddate" IS NOT NULL
      AND DATE("shippeddate") >= DATE("requireddate")
    GROUP BY "employeeid"
)
SELECT
    tot."employeeid"              AS "Employee_ID",
    COALESCE(late.late_orders, 0) AS "Late_Orders",
    ROUND(100.0 * COALESCE(late.late_orders, 0) / tot.total_orders, 2) 
                                   AS "Late_Order_Percentage"
FROM tot
LEFT JOIN late ON tot."employeeid" = late."employeeid"
ORDER BY "Late_Order_Percentage" DESC
LIMIT 3;