WITH season_peaks AS (
  SELECT
    season,
    market,
    name,
    wins,
    MAX(wins) OVER (PARTITION BY season) AS season_max
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE season BETWEEN 1900 AND 2000
    AND market IS NOT NULL          -- exclude rows with missing university name
    AND name   IS NOT NULL          -- exclude rows with missing team nickname
)
SELECT
  market AS university,
  COUNT(*) AS total_peak_seasons
FROM season_peaks
WHERE wins = season_max               -- only seasons where the team had that season's max wins
GROUP BY university
ORDER BY total_peak_seasons DESC, university
LIMIT 5;