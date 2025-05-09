WITH top_states AS (
    SELECT "state"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.ALIEN_DATA
    GROUP BY "state"
    ORDER BY COUNT("id") DESC NULLS LAST
    LIMIT 10
),
state_stats AS (
    SELECT
        a."state",
        COUNT(a."id") AS "total_aliens",
        ROUND(AVG(a."age"), 4) AS "average_age",
        SUM(CASE WHEN a."aggressive" = 0 THEN 1 ELSE 0 END) AS "friendly_count",
        SUM(CASE WHEN a."aggressive" = 1 THEN 1 ELSE 0 END) AS "hostile_count"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.ALIEN_DATA a
    WHERE a."state" IN (SELECT "state" FROM top_states)
    GROUP BY a."state"
)
SELECT COUNT(*) AS "number_of_states"
FROM state_stats
WHERE "friendly_count" > "hostile_count" AND "average_age" > 200;