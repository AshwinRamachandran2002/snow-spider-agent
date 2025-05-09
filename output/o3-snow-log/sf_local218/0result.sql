WITH season_goals AS (      -- goals scored by a team in one season (home or away)
    SELECT
        "home_team_api_id" AS team_id,
        "season",
        SUM("home_team_goal") AS goals
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    WHERE "home_team_api_id" IS NOT NULL
    GROUP BY "home_team_api_id", "season"
    
    UNION ALL
    
    SELECT
        "away_team_api_id" AS team_id,
        "season",
        SUM("away_team_goal") AS goals
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    WHERE "away_team_api_id" IS NOT NULL
    GROUP BY "away_team_api_id", "season"
),

combined_season_goals AS (  -- combine home & away tallies for same team-season
    SELECT
        team_id,
        "season",
        SUM(goals) AS season_goals
    FROM season_goals
    GROUP BY team_id, "season"
),

highest_per_team AS (       -- highest-scoring season for each team
    SELECT
        team_id,
        MAX(season_goals) AS highest_season_goals
    FROM combined_season_goals
    GROUP BY team_id
)

SELECT
    MEDIAN(highest_season_goals) AS "MEDIAN_HIGHEST_SEASON_GOALS"
FROM highest_per_team;