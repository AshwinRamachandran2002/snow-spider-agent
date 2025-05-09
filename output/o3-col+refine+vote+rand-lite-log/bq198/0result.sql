-- Top 5 universities (1900-2000) with the greatest number of seasons
-- in which they matched their own single-season win record
WITH era AS (
  SELECT
    market,
    season,
    wins
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE season BETWEEN 1900 AND 2000          -- restrict to requested era
    AND market IS NOT NULL                    -- exclude missing team names
    AND TRIM(market) <> ''
    AND wins IS NOT NULL                      -- need a win value
),
max_wins AS (                                 -- each school’s best season wins
  SELECT
    market,
    MAX(wins) AS max_wins
  FROM era
  GROUP BY market
),
peak_seasons AS (                             -- seasons that hit that max
  SELECT
    e.market,
    e.season
  FROM era AS e
  JOIN max_wins AS m
    ON e.market = m.market
   AND e.wins   = m.max_wins
)
SELECT
  market AS university,
  COUNT(*) AS peak_win_seasons
FROM peak_seasons
GROUP BY market
ORDER BY peak_win_seasons DESC, university     -- tie-break alphabetically
LIMIT 5;