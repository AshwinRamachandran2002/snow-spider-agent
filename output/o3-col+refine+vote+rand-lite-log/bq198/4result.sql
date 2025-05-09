-- Top 5 schools with the most seasons (1900-2000) in which they posted
-- the single-season highest win total
WITH season_max AS (
  SELECT
    season,
    CONCAT(market, ' ', name) AS school
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE
    season BETWEEN 1900 AND 2000
    AND market IS NOT NULL
    AND name   IS NOT NULL
  QUALIFY
    wins = MAX(wins) OVER (PARTITION BY season)   -- keep only season-high winners
)
SELECT
  school,
  COUNT(*) AS total_peak_seasons
FROM season_max
GROUP BY school
ORDER BY total_peak_seasons DESC, school
LIMIT 5;