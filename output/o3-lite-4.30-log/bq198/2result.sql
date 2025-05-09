WITH max_wins_per_season AS (
  SELECT
    season,
    MAX(wins) AS max_wins
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE season BETWEEN 1900 AND 2000
  GROUP BY season
),
peak_teams AS (
  SELECT
    s.market,          -- university / school name
    s.season
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons` AS s
  JOIN max_wins_per_season AS m
    ON s.season = m.season
   AND s.wins   = m.max_wins          -- team reached that season's win maximum
  WHERE s.market IS NOT NULL          -- exclude missing university names
    AND s.name   IS NOT NULL          -- exclude missing team nicknames
)
SELECT
  market AS team,
  COUNT(*) AS total_peak_seasons
FROM peak_teams
GROUP BY market
ORDER BY total_peak_seasons DESC, team
LIMIT 5;