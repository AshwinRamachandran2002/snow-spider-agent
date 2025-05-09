WITH wins AS (
    -- wins achieved as the home team
    SELECT "home_team_api_id" AS "team_api_id"
    FROM   "Match"
    WHERE  "home_team_goal" > "away_team_goal"
    
    UNION ALL
    
    -- wins achieved as the away team
    SELECT "away_team_api_id" AS "team_api_id"
    FROM   "Match"
    WHERE  "away_team_goal" > "home_team_goal"
), aggregated AS (
    SELECT  "team_api_id",
            COUNT(*) AS "total_wins"
    FROM    wins
    GROUP BY "team_api_id"
)
SELECT  t."team_long_name"      AS "team",
        a."total_wins"          AS "wins"
FROM    aggregated a
JOIN    "Team" t
        ON t."team_api_id" = a."team_api_id"
ORDER BY a."total_wins" DESC,
         t."team_long_name"      -- secondary sort to make ordering deterministic
LIMIT 10;