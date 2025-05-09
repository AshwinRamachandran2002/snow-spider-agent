WITH season_goals AS (
    /* goals scored by every team in every season */
    SELECT "season",
           "home_team_api_id" AS team_api_id,
           "home_team_goal"   AS g
    FROM "Match"
    UNION ALL
    SELECT "season",
           "away_team_api_id",
           "away_team_goal"
    FROM "Match"
),
per_season AS (
    /* total goals per team and season */
    SELECT "season",
           team_api_id,
           SUM(g) AS season_goals
    FROM season_goals
    GROUP BY "season", team_api_id
),
best_per_team AS (
    /* each club's best (highest-scoring) season */
    SELECT team_api_id,
           MAX(season_goals) AS best_season_goals
    FROM per_season
    GROUP BY team_api_id
),
ordered AS (
    /* order the best tallies to extract the median */
    SELECT best_season_goals,
           ROW_NUMBER() OVER (ORDER BY best_season_goals) AS rn,
           COUNT(*)  OVER ()                              AS cnt
    FROM best_per_team
)
SELECT AVG(best_season_goals) AS median_best_season_goals
FROM ordered
WHERE rn IN ( (cnt + 1) / 2,        -- middle row (odd count)
              (cnt + 2) / 2 );      -- upper middle (even count)