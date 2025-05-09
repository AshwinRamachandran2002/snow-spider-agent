SELECT
  market AS team,
  COUNT(*) AS total_peak_seasons
FROM (
  SELECT
    s.season,
    s.market
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons` AS s
  JOIN (
        SELECT
          season,
          MAX(wins) AS max_wins
        FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
        WHERE season BETWEEN 1900 AND 2000
        GROUP BY season
       ) AS m
    ON  s.season = m.season
    AND s.wins   = m.max_wins
  WHERE s.season BETWEEN 1900 AND 2000
    AND s.market IS NOT NULL
    AND s.name   IS NOT NULL
)
GROUP BY team
ORDER BY total_peak_seasons DESC, team
LIMIT 5;