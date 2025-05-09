SELECT s.market AS University, COUNT(*) AS Total_peak_seasons
FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons` s
JOIN (
  SELECT season, MAX(wins) AS max_wins
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_teams_seasons`
  WHERE season BETWEEN 1900 AND 2000
    AND market IS NOT NULL AND TRIM(market) != ''
  GROUP BY season
) m ON s.season = m.season AND s.wins = m.max_wins
WHERE s.season BETWEEN 1900 AND 2000
  AND s.market IS NOT NULL AND TRIM(s.market) != ''
GROUP BY University
ORDER BY Total_peak_seasons DESC
LIMIT 5;