SELECT 
    t."team_long_name" AS team_name,
    COUNT(*)           AS total_wins
FROM (
        SELECT "home_team_api_id" AS team_id
        FROM "Match"
        WHERE "home_team_goal" > "away_team_goal"
        UNION ALL
        SELECT "away_team_api_id" AS team_id
        FROM "Match"
        WHERE "away_team_goal" > "home_team_goal"
     ) AS w
JOIN "Team" AS t
  ON w.team_id = t."team_api_id"
GROUP BY t."team_long_name"
ORDER BY total_wins DESC, t."team_long_name"
LIMIT 10;