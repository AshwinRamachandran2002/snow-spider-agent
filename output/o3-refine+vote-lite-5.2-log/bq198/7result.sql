-- Top 5 universities that most often had the season‑high win total (1900‑2000)
WITH team_seasons AS (
  SELECT
    season,
    market,              -- university / school name
    name,                -- team nickname
    wins
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE
    season BETWEEN 1900 AND 2000
    AND market IS NOT NULL     -- exclude rows with missing university name
    AND name   IS NOT NULL     -- exclude rows with missing team name
),

-- For every season, find the maximum wins recorded
season_max AS (
  SELECT
    season,
    MAX(wins) AS max_wins
  FROM team_seasons
  GROUP BY season
),

-- Teams that reached that season's maximum wins
season_peaks AS (
  SELECT
    ts.season,
    ts.market,
    ts.name
  FROM team_seasons ts
  JOIN season_max sm
    ON ts.season = sm.season
   AND ts.wins   = sm.max_wins
)

-- Count how many seasons each university appeared in season_peaks
SELECT
  market  AS university,
  name    AS team_name,
  COUNT(*) AS peak_performance_seasons
FROM season_peaks
GROUP BY
  market,
  name
ORDER BY
  peak_performance_seasons DESC,
  university
LIMIT 5;