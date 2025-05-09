-- Top-5 universities (by “market”) with the most seasons in which
-- they achieved the single-season win maximum, 1900-2000
WITH season_max AS (
  SELECT
    season,
    MAX(wins) AS max_wins
  FROM
    `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE
    season BETWEEN 1900 AND 2000
  GROUP BY
    season
),
teams_at_peak AS (
  SELECT
    t.market,
    t.season
  FROM
    `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons` AS t
  JOIN
    season_max AS m
  ON  t.season = m.season
  AND t.wins   = m.max_wins
  WHERE
    t.market IS NOT NULL      -- exclude missing school names
    AND t.name   IS NOT NULL
)
SELECT
  market AS university,
  COUNT(*) AS total_peak_seasons
FROM
  teams_at_peak
GROUP BY
  market
ORDER BY
  total_peak_seasons DESC,
  university
LIMIT 5;