WITH team_season_goals AS (
    /* total goals scored by each team in every season */
    SELECT
        "season",
        "team_id",
        SUM("team_goals") AS "season_goals"
    FROM (
        SELECT
            "season",
            "home_team_api_id"  AS "team_id",
            "home_team_goal"    AS "team_goals"
        FROM EU_SOCCER.EU_SOCCER."MATCH"
        WHERE "home_team_api_id" IS NOT NULL
        
        UNION ALL
        
        SELECT
            "season",
            "away_team_api_id"  AS "team_id",
            "away_team_goal"    AS "team_goals"
        FROM EU_SOCCER.EU_SOCCER."MATCH"
        WHERE "away_team_api_id" IS NOT NULL
    ) AS t
    GROUP BY "season", "team_id"
),
team_max_goals AS (
    /* highest-scoring season for every team */
    SELECT
        "team_id",
        MAX("season_goals") AS "max_season_goals"
    FROM team_season_goals
    GROUP BY "team_id"
)
SELECT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "max_season_goals") 
        AS "median_highest_season_goals"
FROM team_max_goals;