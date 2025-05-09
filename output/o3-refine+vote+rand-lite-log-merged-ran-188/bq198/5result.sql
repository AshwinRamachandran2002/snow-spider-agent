WITH season_stats AS (
  SELECT
    season,
    market,                  -- university / school name
    name,                    -- team nickname
    team_id,
    wins,
    MAX(wins) OVER (PARTITION BY season) AS season_max_wins
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE
    season BETWEEN 1900 AND 2000          -- requested time span
    AND market IS NOT NULL                -- exclude missing school names
    AND name   IS NOT NULL
),

season_peak_teams AS (          -- teams that reached the season’s win maximum
  SELECT DISTINCT
    season,
    market,
    team_id
  FROM season_stats
  WHERE wins = season_max_wins
)

SELECT
  market            AS university,
  COUNT(DISTINCT season) AS peak_performance_seasons
FROM season_peak_teams
GROUP BY market
ORDER BY peak_performance_seasons DESC, university
LIMIT 5;