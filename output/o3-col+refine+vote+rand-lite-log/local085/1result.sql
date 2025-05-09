WITH stats AS (
    SELECT
        "employeeid",
        COUNT(*) AS total_orders,
        SUM(
            CASE
                WHEN "shippeddate" IS NOT NULL
                  AND "requireddate" IS NOT NULL
                  AND "shippeddate" >= "requireddate"
                THEN 1 ELSE 0
            END
        ) AS late_orders
    FROM "orders"
    GROUP BY "employeeid"
    HAVING total_orders > 50
),
pct AS (
    SELECT
        "employeeid",
        late_orders,
        ROUND(100.0 * late_orders / total_orders, 4) AS late_pct
    FROM stats
)
SELECT
    "employeeid",
    late_orders,
    late_pct
FROM pct
ORDER BY late_pct DESC
LIMIT 3;