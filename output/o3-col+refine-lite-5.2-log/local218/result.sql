WITH per_match AS (
    SELECT "home_team_api_id" AS "team_api_id",
           "season",
           "home_team_goal" AS "goals"
    FROM "Match"
    UNION ALL
    SELECT "away_team_api_id",
           "season",
           "away_team_goal"
    FROM "Match"
),
season_totals AS (
    SELECT "team_api_id",
           "season",
           SUM("goals") AS "total_goals"
    FROM per_match
    GROUP BY "team_api_id", "season"
),
max_per_team AS (
    SELECT "team_api_id",
           MAX("total_goals") AS "max_goals"
    FROM season_totals
    GROUP BY "team_api_id"
),
ordered AS (
    SELECT "max_goals",
           ROW_NUMBER() OVER (ORDER BY "max_goals") AS rn,
           COUNT(*) OVER ()                       AS cnt
    FROM max_per_team
)
SELECT AVG("max_goals") AS "median_max_goals"
FROM   ordered
WHERE  rn IN ( (cnt + 1) / 2, (cnt + 2) / 2 );