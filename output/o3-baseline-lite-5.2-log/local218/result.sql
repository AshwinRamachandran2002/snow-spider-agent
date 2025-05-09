WITH all_goals AS (                       -- every goal a team scored in a match
    SELECT "home_team_api_id" AS team_id,
           "season",
           "home_team_goal"  AS goals_scored
    FROM   "Match"
    UNION ALL
    SELECT "away_team_api_id",
           "season",
           "away_team_goal"
    FROM   "Match"
),
season_totals AS (                        -- total goals each team scored in each season
    SELECT team_id,
           season,
           SUM(goals_scored) AS total_goals
    FROM   all_goals
    GROUP BY team_id, season
),
highest_team AS (                         -- a team’s best (highest‑scoring) season
    SELECT team_id,
           MAX(total_goals) AS highest_season_goals
    FROM   season_totals
    GROUP BY team_id
),
ordered AS (                              -- order those best seasons to pick the median
    SELECT highest_season_goals,
           ROW_NUMBER() OVER (ORDER BY highest_season_goals)            AS rn,
           COUNT(*)    OVER ()                                          AS cnt
    FROM   highest_team
)
SELECT AVG(highest_season_goals) AS median_highest_season_goals
FROM   ordered
WHERE  rn IN ( (cnt + 1) / 2,   -- middle row for odd count
               (cnt + 2) / 2 ); -- the two middle rows for even count (same row if odd)