WITH all_goals AS (
    SELECT "season",
           "home_team_api_id" AS "team_api_id",
           "home_team_goal"   AS "goals"
    FROM "Match"
    WHERE "home_team_goal" IS NOT NULL
    
    UNION ALL
    
    SELECT "season",
           "away_team_api_id" AS "team_api_id",
           "away_team_goal"   AS "goals"
    FROM "Match"
    WHERE "away_team_goal" IS NOT NULL
),
season_goals AS (
    SELECT "season",
           "team_api_id",
           SUM("goals") AS "total_goals"
    FROM all_goals
    GROUP BY "season", "team_api_id"
),
best_season AS (
    SELECT "team_api_id",
           MAX("total_goals") AS "max_goals"
    FROM season_goals
    GROUP BY "team_api_id"
),
ordered AS (
    SELECT "max_goals",
           ROW_NUMBER() OVER (ORDER BY "max_goals", "team_api_id") AS rn,
           COUNT(*) OVER ()                                       AS cnt
    FROM best_season
)
SELECT ROUND(AVG("max_goals"), 4) AS "median_highest_season_goals"
FROM ordered
WHERE rn IN ( (cnt + 1) / 2, (cnt + 2) / 2 );