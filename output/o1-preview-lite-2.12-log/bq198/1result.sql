SELECT COALESCE(s.market, s.name) AS University, COUNT(*) AS Total_peak_seasons
FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons` s
JOIN (
  SELECT season, MAX(wins) AS max_wins
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE season BETWEEN 1900 AND 2000
    AND wins IS NOT NULL
  GROUP BY season
) m ON s.season = m.season AND s.wins = m.max_wins
WHERE ((s.market IS NOT NULL AND s.market != '') OR (s.name IS NOT NULL AND s.name != ''))
  AND s.wins IS NOT NULL
GROUP BY University
ORDER BY Total_peak_seasons DESC
LIMIT 5;