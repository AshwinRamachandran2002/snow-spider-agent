SELECT
    t."team_long_name" AS "team",
    w."total_wins"
FROM (
    SELECT
        "team_api_id",
        SUM("win_flag") AS "total_wins"
    FROM (
        /* home-side victories */
        SELECT
            "home_team_api_id" AS "team_api_id",
            1                  AS "win_flag"
        FROM "Match"
        WHERE "home_team_goal" > "away_team_goal"
        UNION ALL
        /* away-side victories */
        SELECT
            "away_team_api_id" AS "team_api_id",
            1                  AS "win_flag"
        FROM "Match"
        WHERE "away_team_goal" > "home_team_goal"
    )
    GROUP BY "team_api_id"
) AS w
JOIN "Team" AS t
  ON t."team_api_id" = w."team_api_id"
ORDER BY w."total_wins" DESC
LIMIT 10;