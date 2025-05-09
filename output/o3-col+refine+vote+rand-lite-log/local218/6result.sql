WITH home AS (
    SELECT
        "season",
        "home_team_api_id" AS "team_id",
        SUM("home_team_goal") AS "goals"
    FROM "Match"
    GROUP BY "season", "home_team_api_id"
),
away AS (
    SELECT
        "season",
        "away_team_api_id" AS "team_id",
        SUM("away_team_goal") AS "goals"
    FROM "Match"
    GROUP BY "season", "away_team_api_id"
),
per_season AS (
    SELECT
        "season",
        "team_id",
        SUM("goals") AS "total_goals"
    FROM (
        SELECT * FROM home
        UNION ALL
        SELECT * FROM away
    )
    GROUP BY "season", "team_id"
),
best AS (
    -- best season (most goals) for every team
    SELECT
        "team_id",
        MAX("total_goals") AS "highest_season_goals"
    FROM per_season
    GROUP BY "team_id"
),
ordered AS (
    SELECT
        "highest_season_goals",
        ROW_NUMBER() OVER (ORDER BY "highest_season_goals") AS "rn",
        COUNT(*)  OVER ()                                   AS "cnt"
    FROM best
)
SELECT
    AVG("highest_season_goals") AS "median_highest_season_goals"
FROM ordered
WHERE "rn" IN ( ( "cnt" + 1) / 2,          -- middle row if odd
                ( "cnt" + 2) / 2 );        -- two middle rows if even