SELECT
  ROUND(100.0 * SUM(CASE WHEN health = 'Good' THEN 1 ELSE 0 END) / COUNT(*), 4) AS percent_good_health_bronx
FROM trees
WHERE boroname = 'Bronx';