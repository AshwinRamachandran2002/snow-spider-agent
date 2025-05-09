WITH per_match AS (
    SELECT "season",
           "home_team_api_id" AS "team_id",
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
           "team_id",
           SUM("goals") AS "season_goals"
    FROM per_match
    GROUP BY "season", "team_id"
),
best_season AS (
    SELECT "team_id",
           MAX("season_goals") AS "max_season_goals"
    FROM season_totals
    GROUP BY "team_id"
),
ordered AS (
    SELECT "max_season_goals",
           ROW_NUMBER() OVER (ORDER BY "max_season_goals") AS rn,
           COUNT(*)  OVER () AS cnt
    FROM best_season
)
SELECT AVG("max_season_goals") AS "median_best_season_goals"
FROM ordered
WHERE rn IN (cnt/2 + (cnt % 2),  (cnt/2) + 1);