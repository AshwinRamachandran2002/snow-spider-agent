SELECT
    stats."employeeid",
    stats."late_orders",
    stats."late_pct"
FROM (
    SELECT
        o."employeeid",
        COUNT(*) AS total_orders,
        SUM(
            CASE
                WHEN o."shippeddate" IS NOT NULL
                 AND o."shippeddate" >= o."requireddate" THEN 1
                ELSE 0
            END
        ) AS late_orders,
        100.0 * SUM(
            CASE
                WHEN o."shippeddate" IS NOT NULL
                 AND o."shippeddate" >= o."requireddate" THEN 1
                ELSE 0
            END
        ) / COUNT(*) AS late_pct
    FROM "orders" AS o
    GROUP BY o."employeeid"
    HAVING COUNT(*) > 50
) AS stats
ORDER BY stats."late_pct" DESC
LIMIT 3;