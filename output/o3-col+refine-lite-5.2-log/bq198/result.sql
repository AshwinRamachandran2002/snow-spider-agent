-- Top 5 universities with the most “peak‑performance” seasons (1900‑2000)
WITH season_max AS (                                   -- 1. max wins per season
  SELECT
    season,
    MAX(wins) AS max_wins
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE season BETWEEN 1900 AND 2000
  GROUP BY season
),
peak_teams AS (                                        -- 2. teams that hit that max
  SELECT
    t.market,
    t.name,
    t.season
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons` AS t
  JOIN season_max AS s
    ON t.season = s.season
   AND t.wins   = s.max_wins
  WHERE t.market IS NOT NULL
    AND t.name   IS NOT NULL
)
SELECT                                                  -- 3. count peak seasons per university
  market AS university,
  name   AS team_name,
  COUNT(DISTINCT season) AS peak_performance_seasons
FROM peak_teams
GROUP BY university, team_name
ORDER BY peak_performance_seasons DESC, university
LIMIT 5;