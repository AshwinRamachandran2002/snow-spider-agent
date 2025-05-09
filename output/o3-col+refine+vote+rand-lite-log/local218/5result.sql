WITH per_match AS (
    SELECT "home_team_api_id" AS team_id,
           "season",
           "home_team_goal"   AS goals
    FROM   "Match"
    UNION ALL
    SELECT "away_team_api_id",
           "season",
           "away_team_goal"
    FROM   "Match"
),
per_season AS (
    SELECT team_id,
           season,
           SUM(goals) AS season_goals
    FROM   per_match
    GROUP BY team_id, season
),
max_per_team AS (
    SELECT team_id,
           MAX(season_goals) AS max_season_goals
    FROM   per_season
    GROUP BY team_id
),
ordered AS (
    SELECT max_season_goals,
           ROW_NUMBER() OVER (ORDER BY max_season_goals) AS rn,
           COUNT(*)  OVER ()                             AS cnt
    FROM   max_per_team
)
SELECT AVG(max_season_goals) AS median_max_season_goals
FROM   ordered
WHERE  rn IN ( (cnt + 1) / 2,
               (cnt + 2) / 2 );