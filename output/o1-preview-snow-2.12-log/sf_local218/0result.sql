WITH team_season_goals AS (
    SELECT "team_id", "season", SUM("goals_scored") AS "total_goals"
    FROM (
        SELECT "home_team_api_id" AS "team_id", "season", "home_team_goal" AS "goals_scored"
        FROM EU_SOCCER.EU_SOCCER.MATCH
        UNION ALL
        SELECT "away_team_api_id" AS "team_id", "season", "away_team_goal" AS "goals_scored"
        FROM EU_SOCCER.EU_SOCCER.MATCH
    ) AS goals_per_team_season
    GROUP BY "team_id", "season"
),
team_highest_season_goals AS (
    SELECT "team_id", MAX("total_goals") AS "highest_season_goals"
    FROM team_season_goals
    GROUP BY "team_id"
)
SELECT CAST(MEDIAN("highest_season_goals") AS INT) AS "Median_Highest_Season_Goals"
FROM team_highest_season_goals;