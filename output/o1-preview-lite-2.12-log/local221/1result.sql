SELECT t."team_long_name" AS "team_name",
       COUNT(*) AS "number_of_wins"
FROM (
    SELECT m."home_team_api_id" AS "team_api_id"
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal"
    UNION ALL
    SELECT m."away_team_api_id" AS "team_api_id"
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal"
) AS wins
JOIN "Team" t ON wins."team_api_id" = t."team_api_id"
GROUP BY t."team_long_name"
ORDER BY "number_of_wins" DESC
LIMIT 10;