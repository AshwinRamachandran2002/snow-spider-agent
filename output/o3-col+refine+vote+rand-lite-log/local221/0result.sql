-- Top 10 teams with the highest total number of wins (home-wins + away-wins)
SELECT
    t."team_long_name",
    COALESCE(hw."home_wins", 0) + COALESCE(aw."away_wins", 0) AS "total_wins"
FROM "Team" AS t
LEFT JOIN (
    SELECT "home_team_api_id" AS "team_api_id",
           COUNT(*) AS "home_wins"
    FROM "Match"
    WHERE "home_team_goal" > "away_team_goal"
    GROUP BY "home_team_api_id"
) AS hw
    ON t."team_api_id" = hw."team_api_id"
LEFT JOIN (
    SELECT "away_team_api_id" AS "team_api_id",
           COUNT(*) AS "away_wins"
    FROM "Match"
    WHERE "away_team_goal" > "home_team_goal"
    GROUP BY "away_team_api_id"
) AS aw
    ON t."team_api_id" = aw."team_api_id"
ORDER BY "total_wins" DESC
LIMIT 10;