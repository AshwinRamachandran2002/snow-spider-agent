WITH "WIN_LIST" AS (
    -- wins achieved by the home team
    SELECT 
        "home_team_api_id" AS "team_api_id",
        1 AS "win"
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    WHERE "home_team_goal" > "away_team_goal"
    
    UNION ALL
    
    -- wins achieved by the away team
    SELECT 
        "away_team_api_id" AS "team_api_id",
        1 AS "win"
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    WHERE "away_team_goal" > "home_team_goal"
),
"TEAM_WINS" AS (
    SELECT 
        "team_api_id",
        SUM("win") AS "total_wins"
    FROM "WIN_LIST"
    GROUP BY "team_api_id"
)
SELECT 
    T."team_long_name",
    TW."total_wins"
FROM "TEAM_WINS" TW
JOIN EU_SOCCER.EU_SOCCER."TEAM" T
  ON TW."team_api_id" = T."team_api_id"
ORDER BY TW."total_wins" DESC NULLS LAST
LIMIT 10;