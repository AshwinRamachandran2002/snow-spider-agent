SELECT t."team_long_name" AS "team_name", w."total_wins"
FROM (
  SELECT "team_api_id", SUM("wins") AS "total_wins"
  FROM (
    SELECT m."home_team_api_id" AS "team_api_id", COUNT(*) AS "wins"
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal"
    GROUP BY m."home_team_api_id"
    UNION ALL
    SELECT m."away_team_api_id" AS "team_api_id", COUNT(*) AS "wins"
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal"
    GROUP BY m."away_team_api_id"
  ) AS win_counts
  GROUP BY "team_api_id"
) AS w
INNER JOIN "Team" t
ON w."team_api_id" = t."team_api_id"
ORDER BY w."total_wins" DESC
LIMIT 10;