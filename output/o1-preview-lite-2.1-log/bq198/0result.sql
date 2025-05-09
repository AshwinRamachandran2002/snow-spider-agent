SELECT 
  t.market AS University, 
  COUNT(*) AS Total_peak_seasons
FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons` t
JOIN (
  SELECT season, MAX(wins) AS max_wins
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE season BETWEEN 1900 AND 2000 
    AND market IS NOT NULL AND market != ''
    AND wins IS NOT NULL
  GROUP BY season
) m ON t.season = m.season AND t.wins = m.max_wins
WHERE t.market IS NOT NULL AND t.market != '' 
  AND t.season BETWEEN 1900 AND 2000
GROUP BY t.market
ORDER BY Total_peak_seasons DESC, University
LIMIT 5;