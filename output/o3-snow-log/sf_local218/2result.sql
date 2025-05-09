WITH all_goals AS (
    SELECT 
        "home_team_api_id" AS "team_id",
        "season",
        "home_team_goal" AS "goals"
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "home_team_api_id" IS NOT NULL
    
    UNION ALL
    
    SELECT 
        "away_team_api_id" AS "team_id",
        "season",
        "away_team_goal" AS "goals"
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "away_team_api_id" IS NOT NULL
),
season_goals AS (
    SELECT
        "team_id",
        "season",
        SUM("goals") AS "season_goals"
    FROM all_goals
    GROUP BY "team_id", "season"
),
highest_per_team AS (
    SELECT
        "team_id",
        MAX("season_goals") AS "highest_season_goals"
    FROM season_goals
    GROUP BY "team_id"
)
SELECT 
    MEDIAN("highest_season_goals") AS "median_highest_season_goals"
FROM highest_per_team;