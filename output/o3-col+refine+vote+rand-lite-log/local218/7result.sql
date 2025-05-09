WITH team_season_goals AS (
    /* goals scored by every team in every match (home + away) */
    SELECT season,
           home_team_api_id AS team_api_id,
           home_team_goal   AS goals
    FROM   Match
    UNION ALL
    SELECT season,
           away_team_api_id AS team_api_id,
           away_team_goal   AS goals
    FROM   Match
),
season_totals AS (
    /* total goals each team scored in each season */
    SELECT season,
           team_api_id,
           SUM(goals) AS season_goals
    FROM   team_season_goals
    GROUP  BY season, team_api_id
),
team_best AS (
    /* highest-ever season goal tally for every team */
    SELECT team_api_id,
           MAX(season_goals) AS best_season_goals
    FROM   season_totals
    GROUP  BY team_api_id
),
ordered AS (
    /* order the best tallies and keep row numbers to compute the median */
    SELECT best_season_goals,
           ROW_NUMBER() OVER (ORDER BY best_season_goals) AS rn,
           COUNT(*)  OVER ()                              AS cnt
    FROM   team_best
)
SELECT ROUND(AVG(best_season_goals),4) AS median_highest_season_goals
FROM   ordered
WHERE  rn IN ((cnt + 1) / 2, (cnt + 2) / 2);