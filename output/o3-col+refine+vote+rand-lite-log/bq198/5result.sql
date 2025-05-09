-- Top 5 universities (market) with the most peak-win seasons, 1900-2000
WITH season_max AS (
  SELECT
    season,
    MAX(wins) AS max_wins
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE season BETWEEN 1900 AND 2000
    AND market IS NOT NULL
    AND name   IS NOT NULL          -- exclude rows with missing team names
  GROUP BY season
),
peak_teams AS (
  SELECT
    t.market,
    t.name,
    t.season
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons` AS t
  JOIN season_max AS m
    ON  t.season = m.season
   AND t.wins   = m.max_wins       -- team hit the season’s win maximum
  WHERE t.market IS NOT NULL
    AND t.name   IS NOT NULL
)
SELECT
  market AS university,
  ANY_VALUE(name) AS team_name,    -- representative mascot/nickname
  COUNT(*) AS total_peak_seasons   -- how many times this university hit the max
FROM peak_teams
GROUP BY market
ORDER BY total_peak_seasons DESC
LIMIT 5;