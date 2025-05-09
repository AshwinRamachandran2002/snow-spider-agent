WITH team_season_goals AS (
    /* goals a team scores in every season (home + away) */
    SELECT team_id,
           season,
           SUM(goals) AS season_goals
    FROM (
        SELECT "home_team_api_id"  AS team_id,
               "season",
               "home_team_goal"    AS goals
        FROM   "Match"
        WHERE  "home_team_api_id" IS NOT NULL
        
        UNION ALL
        
        SELECT "away_team_api_id",
               "season",
               "away_team_goal"
        FROM   "Match"
        WHERE  "away_team_api_id" IS NOT NULL
    )
    GROUP BY team_id, season
),
team_max_goals AS (
    /* best (highest‑scoring) season of every team */
    SELECT team_id,
           MAX(season_goals) AS max_goals
    FROM   team_season_goals
    GROUP BY team_id
),
ordered AS (
    /* order those best seasons to prepare for median */
    SELECT max_goals
    FROM   team_max_goals
    ORDER BY max_goals
)
/* median of the best‑season goal totals, rounded to 4 decimals */
SELECT ROUND(AVG(max_goals), 4) AS median_max_season_goals
FROM (
    /* pick the middle value(s); if even take the two middles */
    SELECT max_goals
    FROM   ordered
    LIMIT  2 - (SELECT COUNT(*) FROM ordered) % 2          -- 1 row if odd, 2 rows if even
    OFFSET (SELECT (COUNT(*) - 1) / 2 FROM ordered)        -- start at the middle
);