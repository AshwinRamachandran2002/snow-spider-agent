-- Top 5 universities with the most “peak-performance” seasons (1900-2000)
WITH season_max AS (
  SELECT
    season,
    MAX(wins) AS max_wins
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE season BETWEEN 1900 AND 2000
  GROUP BY season
),
peaks AS (
  SELECT
    s.market AS university,
    COUNT(*) AS peak_seasons
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons` AS s
  JOIN season_max AS mx
    ON s.season = mx.season
   AND s.wins   = mx.max_wins
  -- Exclude records lacking team information
  WHERE s.market IS NOT NULL
    AND s.name   IS NOT NULL
  GROUP BY s.market
)
SELECT
  university,
  peak_seasons
FROM peaks
ORDER BY peak_seasons DESC, university
LIMIT 5;