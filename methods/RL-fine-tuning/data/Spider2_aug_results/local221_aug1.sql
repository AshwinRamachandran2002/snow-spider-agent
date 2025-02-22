-- Task: List each team's total number of home wins
SELECT t."team_long_name" AS "team_name",
       COUNT(*) AS "number_of_home_wins"
FROM "Match" m
JOIN "Team" t ON m."home_team_api_id" = t."team_api_id"
WHERE m."home_team_goal" > m."away_team_goal"
GROUP BY t."team_long_name"
ORDER BY "number_of_home_wins" DESC;