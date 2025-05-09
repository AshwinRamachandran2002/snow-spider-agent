WITH
home AS (
    SELECT "home_team_api_id" AS team_id,
           "season",
           SUM("home_team_goal") AS goals
    FROM "Match"
    GROUP BY "home_team_api_id", "season"
),
away AS (
    SELECT "away_team_api_id" AS team_id,
           "season",
           SUM("away_team_goal") AS goals
    FROM "Match"
    GROUP BY "away_team_api_id", "season"
),
team_season_goals AS (
    SELECT * FROM home
    UNION ALL
    SELECT * FROM away
),
team_season_totals AS (
    SELECT team_id,
           season,
           SUM(goals) AS total_goals
    FROM team_season_goals
    GROUP BY team_id, season
),
team_best_season AS (
    SELECT team_id,
           MAX(total_goals) AS max_season_goals
    FROM team_season_totals
    GROUP BY team_id
),
ordered AS (
    SELECT max_season_goals,
           ROW_NUMBER() OVER (ORDER BY max_season_goals) AS rn,
           COUNT(*) OVER () AS cnt
    FROM team_best_season
)
SELECT AVG(max_season_goals) AS median_highest_season_goals
FROM   ordered
WHERE  rn IN ( (cnt + 1) / 2, (cnt + 2) / 2 );