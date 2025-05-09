SELECT 
    t."employeeid"                                AS "employee_id",
    l."late_orders",
    ROUND(100.0 * l."late_orders" / t."total_orders", 2) AS "late_order_percentage"
FROM (
        SELECT "employeeid",
               COUNT(*) AS "total_orders"
        FROM "orders"
        GROUP BY "employeeid"
     ) AS t
JOIN (
        SELECT "employeeid",
               COUNT(*) AS "late_orders"
        FROM "orders"
        WHERE "shippeddate" >= "requireddate"
        GROUP BY "employeeid"
     ) AS l
  ON t."employeeid" = l."employeeid"
WHERE t."total_orders" > 50
ORDER BY "late_order_percentage" DESC
LIMIT 3;