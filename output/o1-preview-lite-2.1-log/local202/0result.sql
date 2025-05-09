WITH TopStates AS (
    SELECT "state"
    FROM (
        SELECT "state", COUNT(*) AS "alien_count"
        FROM "alien_data"
        GROUP BY "state"
        ORDER BY "alien_count" DESC
        LIMIT 10
    )
),
StateStats AS (
    SELECT
        ad."state",
        ROUND(AVG(ad."age"), 4) AS "average_age",
        ROUND(
            SUM(CASE WHEN ad."type" IN ('nordic', 'green', 'flatwoods') THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
            4
        ) AS "friendly_percentage",
        ROUND(
            SUM(CASE WHEN ad."type" IN ('reptile', 'grey') THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
            4
        ) AS "hostile_percentage"
    FROM "alien_data" ad
    WHERE ad."state" IN (SELECT "state" FROM TopStates)
      AND ad."age" IS NOT NULL
    GROUP BY ad."state"
    HAVING AVG(ad."age") > 200
)
SELECT COUNT(*) AS "Number_of_states"
FROM StateStats
WHERE "friendly_percentage" > "hostile_percentage";