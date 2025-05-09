WITH season_max AS (
  -- get the maximum wins for every season between 1900‑2000
  SELECT
    season,
    MAX(wins) AS max_wins
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE season BETWEEN 1900 AND 2000
    AND market IS NOT NULL            -- exclude missing team names
    AND name   IS NOT NULL
  GROUP BY season
),
peak_teams AS (
  -- teams that reached the seasonal maximum wins
  SELECT
    t.market,
    t.name,
    t.season
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons` AS t
  JOIN season_max AS s
    ON  t.season = s.season
    AND t.wins   = s.max_wins
  WHERE t.market IS NOT NULL
    AND t.name   IS NOT NULL
    AND t.season BETWEEN 1900 AND 2000
)
-- count how many times each team hit the season‑high wins mark
SELECT
  market  AS university,
  COUNT(*) AS peak_seasons
FROM peak_teams
GROUP BY market
ORDER BY peak_seasons DESC, university
LIMIT 5;