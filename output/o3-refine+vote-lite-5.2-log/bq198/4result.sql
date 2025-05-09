WITH valid_seasons AS (
  -- seasons with non‑missing school & team names, 1900‑2000 inclusive
  SELECT
    season,
    market,          -- school / university
    name,            -- team nickname
    team_id,
    wins
  FROM
    `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE
    season BETWEEN 1900 AND 2000
    AND market IS NOT NULL
    AND name   IS NOT NULL
),
season_max AS (
  -- maximum wins recorded in each season
  SELECT
    season,
    MAX(wins) AS max_wins
  FROM
    valid_seasons
  GROUP BY
    season
),
peak_teams AS (
  -- teams that reached the season‑high wins
  SELECT
    v.market,
    v.name,
    v.season
  FROM
    valid_seasons v
  JOIN
    season_max   m
  ON  v.season = m.season
  AND v.wins   = m.max_wins
)
-- count peak‑performance seasons per university
SELECT
  market  AS university,
  COUNT(*) AS peak_performance_seasons
FROM
  peak_teams
GROUP BY
  university
ORDER BY
  peak_performance_seasons DESC,
  university
LIMIT 5;