SELECT t."team_long_name" AS team_name, total_wins.total_wins AS number_of_wins
FROM (
  SELECT team_id, SUM(wins) AS total_wins
  FROM (
    SELECT "home_team_api_id" AS team_id, COUNT(*) AS wins
    FROM "Match"
    WHERE "home_team_goal" > "away_team_goal"
    GROUP BY "home_team_api_id"
    UNION ALL
    SELECT "away_team_api_id" AS team_id, COUNT(*) AS wins
    FROM "Match"
    WHERE "home_team_goal" < "away_team_goal"
    GROUP BY "away_team_api_id"
  ) AS wins_subquery
  GROUP BY team_id
) AS total_wins
JOIN "Team" t ON t."team_api_id" = total_wins.team_id
ORDER BY total_wins.total_wins DESC
LIMIT 10;