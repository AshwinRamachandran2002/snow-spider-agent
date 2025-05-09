WITH season_peaks AS (
  -- 1.  Max wins in every season 1900‑2000
  SELECT
    season,
    MAX(wins) AS max_wins
  FROM
    `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE
    season BETWEEN 1900 AND 2000
    AND wins IS NOT NULL
  GROUP BY
    season
),
teams_at_peak AS (
  -- 2.  Teams that reached the season’s max wins
  SELECT
    t.market,
    t.name,
    t.season
  FROM
    `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons` t
  JOIN
    season_peaks s
  ON  t.season = s.season
  AND t.wins   = s.max_wins
  WHERE
    t.market IS NOT NULL
    AND t.name   IS NOT NULL
)
-- 3.  Count how many times each team hit the season‑high wins
SELECT
  CONCAT(market, ' ', name) AS university,
  COUNT(*) AS seasons_with_peak_wins
FROM
  teams_at_peak
GROUP BY
  university
ORDER BY
  seasons_with_peak_wins DESC,
  university
LIMIT 5;