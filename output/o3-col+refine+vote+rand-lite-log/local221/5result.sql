WITH wins AS (
    -- home wins
    SELECT "home_team_api_id" AS "team_api_id"
    FROM   "Match"
    WHERE  "home_team_goal" > "away_team_goal"
    
    UNION ALL
    
    -- away wins
    SELECT "away_team_api_id" AS "team_api_id"
    FROM   "Match"
    WHERE  "away_team_goal" > "home_team_goal"
)

SELECT
    t."team_long_name" AS "team",
    COUNT(*)           AS "wins"
FROM   wins w
JOIN   "Team" t
       ON t."team_api_id" = w."team_api_id"
GROUP BY
       w."team_api_id"
ORDER BY
       "wins" DESC
LIMIT 10;