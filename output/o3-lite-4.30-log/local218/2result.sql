WITH match_goals AS (
    SELECT "season",
           "home_team_api_id" AS "team_api_id",
           "home_team_goal"   AS "goals"
    FROM "Match"
    UNION ALL
    SELECT "season",
           "away_team_api_id",
           "away_team_goal"
    FROM "Match"
),
season_totals AS (
    SELECT "season",
           "team_api_id",
           SUM("goals") AS "season_goals"
    FROM match_goals
    GROUP BY "season", "team_api_id"
),
best_per_team AS (
    SELECT "team_api_id",
           MAX("season_goals") AS "max_season_goals"
    FROM season_totals
    GROUP BY "team_api_id"
),
ordered AS (
    SELECT "max_season_goals",
           ROW_NUMBER() OVER (ORDER BY "max_season_goals") AS "rn",
           COUNT(*)  OVER ()                               AS "cnt"
    FROM best_per_team
)
SELECT ROUND(AVG("max_season_goals"), 4) AS "median_highest_season_goals"
FROM ordered
WHERE "rn" IN (
        CAST((cnt + 1) / 2 AS INTEGER),
        CAST((cnt + 2) / 2 AS INTEGER)
);