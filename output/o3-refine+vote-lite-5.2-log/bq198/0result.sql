WITH seasons AS (
  SELECT
    season,
    market,
    name,
    wins,
    MAX(wins) OVER (PARTITION BY season) AS max_wins_season
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE
    season BETWEEN 1900 AND 2000
    AND market IS NOT NULL
    AND name   IS NOT NULL
    AND wins   IS NOT NULL
),
peak_seasons AS (
  -- teams that reached the maximum wins for their season
  SELECT
    market,
    name,
    season
  FROM seasons
  WHERE wins = max_wins_season
)
SELECT
  market        AS university,
  name          AS team_name,
  COUNT(*)      AS peak_performance_seasons
FROM peak_seasons
GROUP BY
  market,
  name
ORDER BY
  peak_performance_seasons DESC,
  university
LIMIT 5;