WITH peak_seasons AS (
  SELECT
    CONCAT(market, ' ', name) AS team
  FROM
    `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE
    season BETWEEN 1900 AND 2000
    AND market IS NOT NULL
    AND name   IS NOT NULL
  QUALIFY
    wins = MAX(wins) OVER (PARTITION BY season)
)
SELECT
  team,
  COUNT(*) AS total_peak_seasons
FROM
  peak_seasons
GROUP BY
  team
ORDER BY
  total_peak_seasons DESC,
  team
LIMIT 5;