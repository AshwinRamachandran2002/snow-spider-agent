WITH per_match AS (
    /* goals scored by each team in every match */
    SELECT
        "season",
        "home_team_api_id"  AS "team_api_id",
        COALESCE("home_team_goal",0) AS "goals"
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "home_team_api_id" IS NOT NULL

    UNION ALL

    SELECT
        "season",
        "away_team_api_id"  AS "team_api_id",
        COALESCE("away_team_goal",0) AS "goals"
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "away_team_api_id" IS NOT NULL
),
season_totals AS (
    /* total goals each team scored in every season */
    SELECT
        "team_api_id",
        "season",
        SUM("goals") AS "season_goals"
    FROM per_match
    GROUP BY "team_api_id","season"
),
team_max_season AS (
    /* highest season-goal total for every team */
    SELECT
        "team_api_id",
        MAX("season_goals") AS "max_season_goals"
    FROM season_totals
    GROUP BY "team_api_id"
)
SELECT
    CAST(MEDIAN("max_season_goals") AS NUMBER(38,4)) AS "median_highest_season_goals"
FROM team_max_season;