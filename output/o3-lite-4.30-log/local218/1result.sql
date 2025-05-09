WITH team_season AS (
    SELECT team_id,
           season,
           SUM(goals) AS season_goals
    FROM (
        SELECT "home_team_api_id" AS team_id,
               "season",
               "home_team_goal"        AS goals
        FROM "Match"
        UNION ALL
        SELECT "away_team_api_id",
               "season",
               "away_team_goal"
        FROM "Match"
    )
    GROUP BY team_id, season
),
team_best AS (
    SELECT team_id,
           MAX(season_goals) AS best_goals
    FROM team_season
    GROUP BY team_id
),
ordered AS (
    SELECT best_goals,
           ROW_NUMBER() OVER (ORDER BY best_goals) AS rn,
           COUNT(*)  OVER ()                       AS cnt
    FROM team_best
)
SELECT ROUND(AVG(best_goals), 4) AS median_highest_season_goals
FROM ordered
WHERE rn IN ( (cnt + 1) / 2, (cnt + 2) / 2 );