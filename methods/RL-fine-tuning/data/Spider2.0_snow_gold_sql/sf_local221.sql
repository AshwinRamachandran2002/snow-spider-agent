SELECT T."team_long_name" AS "Team_name", SUM(W."wins") AS "Number_of_wins"
FROM (
    SELECT "home_team_api_id" AS "team_api_id", COUNT(*) AS "wins"
    FROM "EU_SOCCER"."EU_SOCCER"."MATCH"
    WHERE "home_team_goal" > "away_team_goal"
    GROUP BY "home_team_api_id"
    UNION ALL
    SELECT "away_team_api_id" AS "team_api_id", COUNT(*) AS "wins"
    FROM "EU_SOCCER"."EU_SOCCER"."MATCH"
    WHERE "away_team_goal" > "home_team_goal"
    GROUP BY "away_team_api_id"
) W
JOIN "EU_SOCCER"."EU_SOCCER"."TEAM" T
ON W."team_api_id" = T."team_api_id"
GROUP BY T."team_long_name"
ORDER BY SUM(W."wins") DESC NULLS LAST, T."team_long_name"
LIMIT 10;