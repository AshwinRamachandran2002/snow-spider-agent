WITH season_max AS (
  -- For each season between 1900‑2000 find the highest win total
  SELECT
    season,
    MAX(wins) AS max_wins
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE season BETWEEN 1900 AND 2000
  GROUP BY season
),
peak_performances AS (
  -- Keep only the teams that reached the season’s max win total
  SELECT
    t.team_id,
    t.market,
    t.name,
    t.season
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons` AS t
  JOIN season_max AS s
    ON t.season = s.season
   AND t.wins   = s.max_wins
  WHERE t.season BETWEEN 1900 AND 2000
    AND t.market IS NOT NULL   -- exclude missing school names
    AND t.name   IS NOT NULL   -- exclude missing team names
)
SELECT
  ANY_VALUE(CONCAT(market, ' ', name)) AS university,
  COUNT(*) AS peak_seasons
FROM peak_performances
GROUP BY team_id            -- group by the unique school
ORDER BY peak_seasons DESC, university
LIMIT 5;