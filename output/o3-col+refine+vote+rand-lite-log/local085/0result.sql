SELECT
    "employeeid",
    SUM(
        CASE
            WHEN "shippeddate" IS NOT NULL
             AND "shippeddate" >= "requireddate" THEN 1
            ELSE 0
        END
    )                                              AS "late_orders",
    ROUND(
        100.0 * SUM(
            CASE
                WHEN "shippeddate" IS NOT NULL
                 AND "shippeddate" >= "requireddate" THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        4
    )                                              AS "late_percentage"
FROM "orders"
GROUP BY "employeeid"
HAVING COUNT(*) > 50
ORDER BY "late_percentage" DESC
LIMIT 3;