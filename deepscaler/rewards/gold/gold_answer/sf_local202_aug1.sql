-- Task: For the top 10 states by alien population, find the total number of aliens, the number of friendly aliens, the number of hostile aliens, and the average age of aliens in each state.
WITH top_states AS (
    SELECT "state"
    FROM "CITY_LEGISLATION"."CITY_LEGISLATION"."ALIEN_DATA"
    GROUP BY "state"
    ORDER BY COUNT("id") DESC NULLS LAST
    LIMIT 10
)
SELECT
    ts."state",
    COUNT(ad."id") AS "total_aliens",
    SUM(CASE WHEN ad."aggressive" = 0 THEN 1 ELSE 0 END) AS "friendly_aliens",
    SUM(CASE WHEN ad."aggressive" = 1 THEN 1 ELSE 0 END) AS "hostile_aliens",
    ROUND(AVG(ad."age"), 4) AS "average_age"
FROM top_states ts
JOIN "CITY_LEGISLATION"."CITY_LEGISLATION"."ALIEN_DATA" ad
    ON ts."state" = ad."state"
GROUP BY ts."state";