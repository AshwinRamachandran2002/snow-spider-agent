WITH team_match_goals AS (
    -- 1. One row per team per match with the goals they scored
    SELECT 
        "home_team_api_id" AS "team_api_id",
        "season",
        COALESCE("home_team_goal", 0) AS "goals"
    FROM EU_SOCCER.EU_SOCCER.MATCH
    
    UNION ALL
    
    SELECT 
        "away_team_api_id" AS "team_api_id",
        "season",
        COALESCE("away_team_goal", 0) AS "goals"
    FROM EU_SOCCER.EU_SOCCER.MATCH
),
team_season_goals AS (
    -- 2. Total goals each team scored in every season
    SELECT 
        "team_api_id",
        "season",
        SUM("goals") AS "season_goals"
    FROM team_match_goals
    GROUP BY 
        "team_api_id",
        "season"
),
team_best_season AS (
    -- 3. Highest-scoring season for each team
    SELECT
        "team_api_id",
        MAX("season_goals") AS "highest_season_goals"
    FROM team_season_goals
    GROUP BY 
        "team_api_id"
)
-- 4. Median of those highest season-goal totals
SELECT 
    MEDIAN("highest_season_goals") AS "median_of_highest_season_goals"
FROM team_best_season;