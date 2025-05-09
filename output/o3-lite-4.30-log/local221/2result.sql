SELECT
    t."team_long_name" AS team_name,
    w.total_wins
FROM (
    SELECT
        team_api_id,
        COUNT(*) AS total_wins
    FROM (
        SELECT "home_team_api_id" AS team_api_id
        FROM "Match"
        WHERE "home_team_goal" > "away_team_goal"
        UNION ALL
        SELECT "away_team_api_id"
        FROM "Match"
        WHERE "away_team_goal" > "home_team_goal"
    )
    GROUP BY team_api_id
) AS w
JOIN "Team" AS t
    ON t."team_api_id" = w.team_api_id
ORDER BY w.total_wins DESC, t."team_long_name" ASC
LIMIT 10;