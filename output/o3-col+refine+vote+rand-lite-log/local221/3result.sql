SELECT
    T."team_long_name" AS "team_name",
    W."wins"
FROM (
    SELECT
        "team_api_id",
        COUNT(*) AS "wins"
    FROM (
        SELECT "home_team_api_id" AS "team_api_id"
        FROM "Match"
        WHERE "home_team_goal" > "away_team_goal"
        UNION ALL
        SELECT "away_team_api_id"
        FROM "Match"
        WHERE "away_team_goal" > "home_team_goal"
    )
    GROUP BY "team_api_id"
) AS W
JOIN "Team" AS T
  ON T."team_api_id" = W."team_api_id"
ORDER BY
    W."wins" DESC
LIMIT 10;