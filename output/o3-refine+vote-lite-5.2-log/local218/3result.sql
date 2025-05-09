WITH team_match_goals AS (
    /* one row per team per match with the goals they scored */
    SELECT "home_team_api_id" AS team_id,
           "season",
           "home_team_goal" AS goals
    FROM   "Match"
    UNION ALL
    SELECT "away_team_api_id",
           "season",
           "away_team_goal"
    FROM   "Match"
),
team_season_goals AS (
    /* total goals each team scored in every season */
    SELECT team_id,
           season,
           SUM(goals) AS season_goals
    FROM   team_match_goals
    GROUP BY team_id, season
),
team_max_season_goals AS (
    /* highest‑scoring season for every team */
    SELECT team_id,
           MAX(season_goals) AS max_season_goals
    FROM   team_season_goals
    GROUP BY team_id
),
ordered AS (
    /* prepare ordered list to pick the middle value(s) */
    SELECT max_season_goals,
           ROW_NUMBER() OVER (ORDER BY max_season_goals) AS rn,
           COUNT(*)    OVER ()                               AS cnt
    FROM   team_max_season_goals
)
SELECT ROUND(AVG(max_season_goals), 4) AS median_highest_season_goals
FROM   ordered
WHERE  rn IN ( (cnt + 1) / 2,  (cnt + 2) / 2 );