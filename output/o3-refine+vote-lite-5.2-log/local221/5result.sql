WITH all_wins AS (
    /* Home‑team victories */
    SELECT "home_team_api_id" AS team_api_id
    FROM "Match"
    WHERE "home_team_goal" > "away_team_goal"

    UNION ALL

    /* Away‑team victories */
    SELECT "away_team_api_id" AS team_api_id
    FROM "Match"
    WHERE "away_team_goal" > "home_team_goal"
)

SELECT
    t."team_long_name" AS team_name,
    COUNT(*)           AS win_count
FROM all_wins w
JOIN "Team" t
  ON t."team_api_id" = w.team_api_id
GROUP BY t."team_api_id", t."team_long_name"
ORDER BY win_count DESC, team_name ASC
LIMIT 10;