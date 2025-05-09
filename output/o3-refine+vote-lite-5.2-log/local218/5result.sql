WITH all_team_goals AS (
    /* list every goal a team scored in each match */
    SELECT "season",
           "home_team_api_id" AS team_id,
           "home_team_goal"     AS goals
    FROM   "Match"
    UNION ALL
    SELECT "season",
           "away_team_api_id",
           "away_team_goal"
    FROM   "Match"
),
season_goals AS (
    /* total goals each team scored in a given season */
    SELECT team_id,
           season,
           SUM(goals) AS goals
    FROM   all_team_goals
    GROUP  BY team_id, season
),
team_best AS (
    /* highest‑scoring season for every team */
    SELECT team_id,
           MAX(goals) AS best_goals
    FROM   season_goals
    GROUP  BY team_id
),
ordered AS (
    /* order those best‑season figures to locate the median */
    SELECT best_goals,
           ROW_NUMBER() OVER (ORDER BY best_goals)        AS rn,
           COUNT(*)   OVER ()                              AS cnt
    FROM   team_best
)
SELECT ROUND(AVG(best_goals), 4) AS median_highest_season_goals
FROM   ordered
WHERE  rn IN ( (cnt + 1) / 2,  (cnt + 2) / 2 );