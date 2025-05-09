WITH home_wins AS (
    SELECT "home_team_api_id" AS "team_api_id", COUNT(*) AS "wins"
    FROM "EU_SOCCER"."EU_SOCCER"."MATCH"
    WHERE "home_team_goal" > "away_team_goal"
    GROUP BY "home_team_api_id"
),
away_wins AS (
    SELECT "away_team_api_id" AS "team_api_id", COUNT(*) AS "wins"
    FROM "EU_SOCCER"."EU_SOCCER"."MATCH"
    WHERE "away_team_goal" > "home_team_goal"
    GROUP BY "away_team_api_id"
),
total_wins AS (
    SELECT "team_api_id", SUM("wins") AS "total_wins"
    FROM (
        SELECT * FROM home_wins
        UNION ALL
        SELECT * FROM away_wins
    ) AS combined_wins
    GROUP BY "team_api_id"
)
SELECT t."team_long_name" AS "Team_name", w."total_wins" AS "Number_of_wins"
FROM total_wins w
JOIN "EU_SOCCER"."EU_SOCCER"."TEAM" t ON w."team_api_id" = t."team_api_id"
ORDER BY w."total_wins" DESC NULLS LAST
LIMIT 10;