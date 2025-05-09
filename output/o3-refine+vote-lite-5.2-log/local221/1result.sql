WITH wins AS (
    -- Home team wins
    SELECT "home_team_api_id" AS team_id
    FROM "Match"
    WHERE "home_team_goal" > "away_team_goal"
    
    UNION ALL
    
    -- Away team wins
    SELECT "away_team_api_id" AS team_id
    FROM "Match"
    WHERE "away_team_goal" > "home_team_goal"
)

SELECT
    t."team_long_name"        AS team,
    COUNT(*)                  AS wins
FROM wins w
JOIN "Team" t
  ON t."team_api_id" = w.team_id
GROUP BY t."team_long_name"
ORDER BY wins DESC, team ASC
LIMIT 10;