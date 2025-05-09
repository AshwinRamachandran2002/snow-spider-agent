WITH "match_goals" AS (
    /* goals scored by each team in every match */
    SELECT 
        "season",
        "home_team_api_id"   AS "team_id",
        "home_team_goal"     AS "goals"
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    WHERE "home_team_api_id" IS NOT NULL

    UNION ALL

    SELECT 
        "season",
        "away_team_api_id"   AS "team_id",
        "away_team_goal"     AS "goals"
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    WHERE "away_team_api_id" IS NOT NULL
),
"season_goals" AS (
    /* total goals a team scored in each season */
    SELECT
        "team_id",
        "season",
        SUM("goals") AS "season_goals"
    FROM "match_goals"
    GROUP BY "team_id", "season"
),
"team_max_goals" AS (
    /* highest season-goal tally for every team */
    SELECT
        "team_id",
        MAX("season_goals") AS "max_season_goals"
    FROM "season_goals"
    GROUP BY "team_id"
)
SELECT
    MEDIAN("max_season_goals") AS "median_highest_season_goals"
FROM "team_max_goals";