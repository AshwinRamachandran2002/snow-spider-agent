SELECT COUNT(*) AS "Number_of_states"
FROM (
    SELECT "state",
        AVG("age") AS "average_age",
        SUM(CASE WHEN "aggressive" = 0 THEN 1 ELSE 0 END) AS "friendly_count",
        SUM(CASE WHEN "aggressive" = 1 THEN 1 ELSE 0 END) AS "hostile_count"
    FROM "alien_data"
    WHERE "state" IN (
        SELECT "state"
        FROM "alien_data"
        GROUP BY "state"
        ORDER BY COUNT(*) DESC
        LIMIT 10
    )
    GROUP BY "state"
    HAVING "friendly_count" > "hostile_count" AND AVG("age") > 200
);