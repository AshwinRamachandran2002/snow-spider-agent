WITH top_states AS (
    SELECT "state"
    FROM "CITY_LEGISLATION"."CITY_LEGISLATION"."ALIEN_DATA"
    GROUP BY "state"
    ORDER BY COUNT("id") DESC NULLS LAST
    LIMIT 10
),
state_stats AS (
    SELECT
        ts."state",
        COUNT(ad."id") AS "total_aliens",
        SUM(CASE WHEN ad."aggressive" = 0 THEN 1 ELSE 0 END) AS "friendly_aliens",
        SUM(CASE WHEN ad."aggressive" = 1 THEN 1 ELSE 0 END) AS "hostile_aliens",
        ROUND(AVG(ad."age"), 4) AS "average_age"
    FROM top_states ts
    JOIN "CITY_LEGISLATION"."CITY_LEGISLATION"."ALIEN_DATA" ad
        ON ts."state" = ad."state"
    GROUP BY ts."state"
)
SELECT COUNT(*) AS "number_of_states"
FROM state_stats
WHERE
    "friendly_aliens" > "hostile_aliens"
    AND "average_age" > 200;