WITH team_wins AS (
    /* wins achieved by home teams */
    SELECT "home_team_api_id" AS team_api_id
    FROM "Match"
    WHERE "home_team_goal" IS NOT NULL
      AND "away_team_goal" IS NOT NULL
      AND "home_team_goal" > "away_team_goal"
    
    UNION ALL
    
    /* wins achieved by away teams */
    SELECT "away_team_api_id" AS team_api_id
    FROM "Match"
    WHERE "home_team_goal" IS NOT NULL
      AND "away_team_goal" IS NOT NULL
      AND "away_team_goal" > "home_team_goal"
)

SELECT
    T."team_long_name"        AS team_name,
    COUNT(*)                  AS win_count
FROM team_wins  W
JOIN "Team"     T  ON T."team_api_id" = W.team_api_id
GROUP BY W.team_api_id
ORDER BY win_count DESC, team_name ASC
LIMIT 10;