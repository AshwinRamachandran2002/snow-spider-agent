WITH season_stats AS (
  SELECT
    season,
    market,           -- university / school name
    name,             -- team nickname
    wins
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE
    season BETWEEN 1900 AND 2000          -- requested period
    AND market IS NOT NULL                -- exclude missing team names
    AND name   IS NOT NULL
    AND wins   IS NOT NULL                -- exclude missing win totals
),
season_max AS (                             -- maximum wins each season
  SELECT
    season,
    MAX(wins) AS max_wins
  FROM season_stats
  GROUP BY season
),
peak_teams AS (                             -- teams that hit that max
  SELECT
    s.market,
    s.season
  FROM season_stats s
  JOIN season_max m
    ON s.season = m.season
   AND s.wins   = m.max_wins
)
SELECT
  market                 AS university,
  COUNT(*)               AS peak_performance_seasons
FROM peak_teams
GROUP BY market
ORDER BY peak_performance_seasons DESC, university
LIMIT 5;