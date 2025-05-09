-- Top 5 universities with the most seasons (1900-2000) in which
-- they posted the single-season maximum wins, excluding missing team names
WITH seasons AS (
  SELECT season,
         market,
         name,
         wins
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE season BETWEEN 1900 AND 2000
    AND name IS NOT NULL            -- drop records without a team name
),
max_wins AS (
  SELECT season,
         MAX(wins) AS max_wins
  FROM seasons
  GROUP BY season
),
leaders AS (
  -- teams that hit the max-wins mark in each season
  SELECT s.market,
         s.name,
         s.season
  FROM seasons s
  JOIN max_wins m
    ON s.season = m.season
   AND s.wins   = m.max_wins
),
peak_counts AS (
  -- count how many seasons each school achieved that distinction
  SELECT market,
         name,
         COUNT(*) AS peak_seasons
  FROM leaders
  GROUP BY market, name
)
SELECT market       AS university,
       name         AS team_name,
       peak_seasons
FROM peak_counts
ORDER BY peak_seasons DESC, university
LIMIT 5;