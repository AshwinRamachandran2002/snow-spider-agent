WITH team_season_goals AS (
    /* total goals each team scored per season */
    SELECT home_team_api_id  AS team_id,
           season,
           SUM(home_team_goal) AS season_goals
    FROM   Match
    GROUP  BY home_team_api_id, season

    UNION ALL

    SELECT away_team_api_id  AS team_id,
           season,
           SUM(away_team_goal) AS season_goals
    FROM   Match
    GROUP  BY away_team_api_id, season
),
team_max AS (
    /* highest season‑goal tally for every team */
    SELECT team_id,
           MAX(season_goals) AS highest_goals
    FROM   team_season_goals
    GROUP  BY team_id
),
ordered AS (
    /* rank the values to locate the median position(s) */
    SELECT highest_goals,
           ROW_NUMBER() OVER (ORDER BY highest_goals) AS rn,
           COUNT(*)    OVER ()                       AS cnt
    FROM   team_max
)
SELECT ROUND(AVG(highest_goals),4) AS median_highest_season_goals
FROM   ordered
WHERE  rn IN ( (cnt + 1)/2,          /* middle row if odd count */
               (cnt + 2)/2 );        /* two middles if even count */