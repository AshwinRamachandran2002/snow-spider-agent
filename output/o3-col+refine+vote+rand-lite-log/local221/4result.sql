-- top 10 teams with the highest total wins (home-wins + away-wins) across all leagues & seasons
SELECT
    T."team_long_name"          AS "team",
    COUNT(*)                    AS "wins"
FROM (
        SELECT "home_team_api_id" AS "team_id"
        FROM   "Match"
        WHERE  "home_team_goal" > "away_team_goal"

        UNION ALL

        SELECT "away_team_api_id" AS "team_id"
        FROM   "Match"
        WHERE  "away_team_goal" > "home_team_goal"
     ) AS W
JOIN "Team" T
  ON T."team_api_id" = W."team_id"
GROUP BY W."team_id"
ORDER BY "wins" DESC
LIMIT 10;