-- Task: Find the highest number of goals each team scored in any season. Limit the results to 100 teams.
WITH goals_per_club AS (
    SELECT 
        "team",
        "season",
        SUM("goals") AS "total_goals"
    FROM (
        SELECT 
            "home_team_api_id" AS "team",
            "season",
            "home_team_goal" AS "goals"
        FROM 
            EU_SOCCER.EU_SOCCER."MATCH"
        UNION ALL
        SELECT 
            "away_team_api_id" AS "team",
            "season",
            "away_team_goal" AS "goals"
        FROM 
            EU_SOCCER.EU_SOCCER."MATCH"
    ) AS "goals_data"
    GROUP BY 
        "team", "season"
)
SELECT 
    "team",
    MAX("total_goals") AS "max_goals"
FROM 
    goals_per_club
GROUP BY 
    "team"
LIMIT 100;