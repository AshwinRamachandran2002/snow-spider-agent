-- Top 5 universities (1900‑2000) with the most seasons
-- in which they recorded the single‑season high for wins
WITH season_stats AS (
  SELECT
    season,
    market,                     -- university / school
    name,                       -- team nickname
    wins
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE season BETWEEN 1900 AND 2000
    AND market IS NOT NULL      -- exclude missing school names
    AND name   IS NOT NULL      -- exclude missing team names
    AND wins   IS NOT NULL
),
max_wins_per_season AS (       -- identify the maximum wins each season
  SELECT
    season,
    MAX(wins) AS max_wins
  FROM season_stats
  GROUP BY season
),
season_leaders AS (            -- teams that matched the season’s max wins
  SELECT
    s.market,
    s.name,
    s.season
  FROM season_stats s
  JOIN max_wins_per_season m
    ON s.season = m.season
   AND s.wins   = m.max_wins
),
leader_counts AS (             -- count how many seasons each team led
  SELECT
    market,
    name,
    COUNT(DISTINCT season) AS seasons_with_max_wins
  FROM season_leaders
  GROUP BY market, name
)
SELECT
  market   AS university,
  name     AS team_name,
  seasons_with_max_wins
FROM leader_counts
ORDER BY seasons_with_max_wins DESC, university
LIMIT 5;