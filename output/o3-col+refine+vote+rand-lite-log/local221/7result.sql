SELECT
    t."team_long_name",
    w."total_wins"
FROM (
    SELECT
        team_api_id,
        SUM(wins) AS total_wins
    FROM (
        SELECT
            "home_team_api_id" AS team_api_id,
            COUNT(*)            AS wins
        FROM "Match"
        WHERE "home_team_goal" > "away_team_goal"
        GROUP BY "home_team_api_id"

        UNION ALL

        SELECT
            "away_team_api_id" AS team_api_id,
            COUNT(*)            AS wins
        FROM "Match"
        WHERE "away_team_goal" > "home_team_goal"
        GROUP BY "away_team_api_id"
    )
    GROUP BY team_api_id
) w
JOIN "Team" t
  ON t."team_api_id" = w.team_api_id
ORDER BY w.total_wins DESC
LIMIT 10;