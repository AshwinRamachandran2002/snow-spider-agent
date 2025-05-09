-- Top 5 universities (market) with the most seasons
-- in which they recorded the single-season maximum win total
-- between 1900 and 2000, excluding rows with missing team names.
WITH season_max AS (
  -- Maximum wins for every season in the range
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
peak_seasons AS (
  -- Teams that matched that season’s max wins
  SELECT
    s.market,
    s.name,
    s.season
  FROM
    `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons` AS s
  JOIN
    season_max AS m
  ON
    s.season = m.season
    AND s.wins = m.max_wins
  WHERE
    s.season BETWEEN 1900 AND 2000
    AND s.market IS NOT NULL      -- exclude missing school names
    AND s.name   IS NOT NULL      -- exclude missing team names
),
tally AS (
  -- Count how many times each university hit the season max
  SELECT
    market AS university,
    COUNT(*) AS total_peak_seasons
  FROM
    peak_seasons
  GROUP BY
    market
)
SELECT
  university,
  total_peak_seasons
FROM
  tally
ORDER BY
  total_peak_seasons DESC,
  university
LIMIT
  5;